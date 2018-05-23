package t::Util;

use strict;
use warnings;
use Test::RedisServer;
use Net::EmptyPort qw/ empty_port wait_port /;
use Carp;
use Test::More;
use Time::HiRes qw/ sleep gettimeofday tv_interval /;

use Exporter 'import';
our @EXPORT_OK = qw/ redis_server redis_setlock /;

$Redis::Setlock::WAIT_QUEUE = $ENV{WAIT_QUEUE};

sub redis_server {
    my $redis_server;
    my $port = empty_port();
    eval {
        $redis_server = Test::RedisServer->new( conf => {
            port => $port,
            save => "",
        })
    } or plan skip_all => 'redis-server is required to this test';
    wait_port($port, 10);
    return $redis_server;
}

sub timer(&) {
    my $code_ref = shift;
    my $t0 = [ gettimeofday ];
    my $r = $code_ref->();
    my $elapsed = tv_interval($t0);
    return $r, $elapsed;
}

sub redis_setlock {
    my @args = @_;

    if ($ENV{COMMAND}) {
        @args = trim_args(@args) if $ENV{COMMAND} eq "setlock";
        timer { system_with_pass_signal($ENV{COMMAND}, @args) };
    }
    else {
        timer { Redis::Setlock->run(@args) };
    }
}

sub system_with_pass_signal {
    my @command = @_;
    if (my $pid = fork()) {
        warn "system_with_pass_signal parent";
        local $SIG{CHLD} = sub { };
        local $SIG{TERM} = $SIG{HUP} = $SIG{INT} = $SIG{QUIT} = sub {
            my $signal = shift;
            warn "Got signal $signal";
            kill $signal, $pid;
        };
        wait;
    }
    else {
        warn "system_with_pass_signal child @command";
        exec @command;
        die "???";
    }
    my $code = $?;
    if ($code == -1) {
        return $code;
    }
    elsif ($code & 127) {
        return $code;
    }
    else {
        $code = $code >> 8; # to raw exit code
        return $code;
    }
}

sub trim_args {
    my @args = @_;
    my @result;
    while (my $arg = shift @args) {
        if ( $arg eq "--redis" || $arg eq "--expires" ) {
            shift @args;
            next;
        }
        elsif ( $arg eq "--keep" ) {
            next;
        }
        push @result, $arg;
    }
    return @result;
}

1;
