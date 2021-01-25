package Redis::Setlock;
use 5.008001;
use strict;
use warnings;
use Redis;
use Getopt::Long ();
use Pod::Usage;
use Log::Minimal;
use Try::Tiny;
use Time::HiRes qw/ sleep /;
use Carp;
use Digest::SHA qw/ sha1_hex /;
use Guard ();

our $VERSION                  = "0.13";
our $DEFAULT_EXPIRES          = 86400;
our $RETRY_INTERVAL           = 0.5;
our $BLOCKING_KEY_POSTFIX     = ":wait";
our $WAIT_QUEUE               = 0;
our $WARN_LOCK_TIME_THRESHOLD = 0;

use constant {
    EXIT_CODE_ERROR => 111,
};

use constant UNLOCK_LUA_SCRIPT => <<'END_OF_SCRIPT'
if redis.call("get",KEYS[1]) == ARGV[1]
then
    return redis.call("del",KEYS[1])
else
    return 0
end
END_OF_SCRIPT
    ;

use constant BLOCKING_UNLOCK_LUA_SCRIPT_TMPL => <<'END_OF_SCRIPT'
if redis.call("get",KEYS[1]) == ARGV[1]
    then
    local q = KEYS[1].."%s"
    redis.call("del", KEYS[1])
    redis.call("expire", q, 60)
    return redis.call("lpush", q, ARGV[1])
else
    return 0
end
END_OF_SCRIPT
    ;

sub BLOCKING_UNLOCK_LUA_SCRIPT {
    sprintf BLOCKING_UNLOCK_LUA_SCRIPT_TMPL, $BLOCKING_KEY_POSTFIX;
}

sub parse_options {
    my (@argv) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case auto_help bundling pass_through/]
    );
    my $opt = {
        wait      => 1,
        exit_code => EXIT_CODE_ERROR,
    };
    $p->getoptionsfromarray(\@argv, $opt, qw/
        redis=s
        expires=i
        keep
        n
        N
        x
        X
        version
    /) or pod2usage;

    if ($opt->{version}) {
        print STDERR "version: $VERSION\n";
        exit 0;
    }
    $opt->{wait}      = 0 if $opt->{n};  # no delay
    $opt->{exit_code} = 0 if $opt->{x};  # exit code 0
    $opt->{expires}   = $DEFAULT_EXPIRES unless defined $opt->{expires};

    return ($opt, @argv);
}

sub lock_guard {
    my $class = shift;
    my ($redis, $key, $expires, $wait) = @_;

    my $opt = {
        wait    => $wait,
        expires => defined $expires ? $expires : $DEFAULT_EXPIRES,
    };
    my $start = [ Time::HiRes::gettimeofday ];
    my $token = try_get_lock($redis, $opt, $key)
        or return;

    return Guard::guard {
        my $elapsed = Time::HiRes::tv_interval($start);
        if ($opt->{expires} < $elapsed) {
            warnf "guard(token:%s) seems to be already expired. elasped %s sec", $token, $elapsed;
        } elsif (0 < $WARN_LOCK_TIME_THRESHOLD && $WARN_LOCK_TIME_THRESHOLD < $elapsed) {
            warnf "guard(token:%s) elasped %s sec", $token, $elapsed;
        }
        release_lock($redis, $opt, $key, $token);
    };
}

sub run {
    my $class = shift;

    local $Log::Minimal::PRINT = \&log_minimal_print;

    my ($opt, $key, @command) = parse_options(@_);

    pod2usage() if !defined $key || @command == 0;

    my $redis = connect_to_redis_server($opt)
        or return EXIT_CODE_ERROR;

    validate_redis_version($redis)
        or return EXIT_CODE_ERROR;

    if ( my $token = try_get_lock($redis, $opt, $key) ) {
        my $code = invoke_command(@command);
        release_lock($redis, $opt, $key, $token);
        debugf "exit with code %d", $code;
        return $code;
    }
    else {
        # couldnot get lock
        if ($opt->{exit_code}) {
            critf "unable to lock %s.", $key;
            return $opt->{exit_code};
        }
        debugf "exit with code 0";
        return 0; # by option x
    }
}

sub connect_to_redis_server {
    my $opt = shift;
    try {
        Redis->new(
            server    => $opt->{redis},
            reconnect => $opt->{wait} ? $opt->{expires} : 0,
            every     => $RETRY_INTERVAL * 1000, # to msec
        );
    }
    catch {
        my $e = $_;
        my $error = (split(/\n/, $e))[0];
        critf "Redis server seems down: %s", $error;
        return;
    };
}

sub validate_redis_version {
    my $redis = shift;
    my $version = $redis->info->{redis_version};
    debugf "Redis version is: %s", $version;
    my ($major, $minor, $rev) = split /\./, $version;
    if ( $major >= 3
      || $major == 2 && $minor >= 7
      || $major == 2 && $minor == 6 && $rev >= 12
    ) {
        # ok
        return 1;
    }
    critf "required Redis server version >= 2.6.12. current server version is %s", $version;
    return;
}

sub try_get_lock {
    my ($redis, $opt, $key) = @_;
    my $got_lock;
    my $token = create_token();
 GET_LOCK:
    while (1) {
        my @args = ($key, $token, "EX", $opt->{expires}, "NX");
        debugf "redis: SET @args";
        $got_lock = $redis->set(@args);
        if ($got_lock) {
            debugf "got lock: %s", $key;
            last GET_LOCK;
        }
        elsif (!$opt->{wait}) { # no delay by option n
            debugf "no delay mode. exit";
            last GET_LOCK;
        }
        debugf "unable to lock. waiting for release";
        if ($WAIT_QUEUE) {
            $redis->blpop("$key${BLOCKING_KEY_POSTFIX}", $opt->{expires});
        }
        else {
            sleep $RETRY_INTERVAL;
        }
    }
    return $token if $got_lock;
}

sub release_lock {
    my ($redis, $opt, $key, $token) = @_;
    if ($opt->{keep}) {
        debugf "Keep lock key %s", $key;
        return;
    }

    debugf "Release lock key %s", $key;
    my $script = $WAIT_QUEUE ? BLOCKING_UNLOCK_LUA_SCRIPT : UNLOCK_LUA_SCRIPT;
    my $sha1   = sha1_hex($script);
    try {
        $redis->evalsha($sha1, 1, $key, $token);
    }
    catch {
        my $e = $_;
        if ($e =~ /NOSCRIPT/) {
            $redis->eval($script, 1, $key, $token);
        }
        else {
            croak $e;
        }
    };
}

sub invoke_command {
    my @command = @_;
    debugf "invoking command: @command";
    if (my $pid = fork()) {
        local $SIG{CHLD} = sub { };
        local $SIG{TERM} = $SIG{HUP} = $SIG{INT} = $SIG{QUIT} = sub {
            my $signal = shift;
            warnf "Got signal %s", $signal;
            kill $signal, $pid;
        };
        wait;
    }
    else {
        exec @command;
        die;
    }
    my $code = $?;
    if ($code == -1) {
        critf "faildto execute: %s", $!;
        return $code;
    }
    elsif ($code & 127) {
        debugf "child died with signal %d", $code & 127;
        return $code;
    }
    else {
        $code = $code >> 8;       # to raw exit code
        debugf "child exit with code: %s", $code;
        return $code;
    }
}

sub log_minimal_print {
    my ( $time, $type, $message, $trace) = @_;
    warn "$time $$ $type $message\n";
}

sub create_token {
    Time::HiRes::time() . rand();
}

1;
__END__

=encoding utf-8

=for stopwords setlock

=head1 NAME

Redis::Setlock - Like the setlock command using Redis.

=head1 SYNOPSIS

    $ redis-setlock [-nNxX] KEY program [ arg ... ]

    --redis (Default: 127.0.0.1:6379): redis-host:redis-port
    --expires (Default: 86400): The lock will be auto-released after the expire time is reached.
    --keep: Keep the lock after invoked command exited.
    -n: No delay. If KEY is locked by another process, redis-setlock gives up.
    -N: (Default.) Delay. If KEY is locked by another process, redis-setlock waits until it can obtain a new lock.
    -x: If KEY is locked, redis-setlock exits zero.
    -X: (Default.) If KEY is locked, redis-setlock prints an error message and exits nonzero.


Using in your perl code.

   use Redis::Setlock;
   use Redis;  # or Redis::Fast
   my $redis = Redis->new( server => 'redis.example.com:6379' );
   if ( my $guard = Redis::Setlock->lock_guard($redis, "key", 60) ) {
      # got a lock!
      ...
      # unlock at guard destroyed.
   }
   else {
      # couldnot get lock
   }


=head1 DESCRIPTION

Redis::Setlock is a like the setlock command using Redis.

=head1 REQUIREMENTS

Redis Server >= 2.6.12.

=head1 METHODS

=over 4

=item B<new>(%args)

=item B<lock_guard>($redis, $lock_name, $expires, $blocking)

Creates Guard::guard object when the lock got.

The lock is released at the guard is destroyed.

If $blocking is true, lock_guard will be blocked until getting a lock. Otherwise returns immedetly when the lock is held by others .

=back

=head1 Variables

=over 4

=item B<$WAIT_QUEUE>

Default: 0

If set to 1, Use the Redis BLPOP command to wait for unlocking instead of periodical polling.

=item B<$WARN_LOCK_TIME_THRESHOLD>

Default: 0

If set to number over 0, put a warnings message to stderr when a lock guard unlocked spent over that seconds.

=back

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut
