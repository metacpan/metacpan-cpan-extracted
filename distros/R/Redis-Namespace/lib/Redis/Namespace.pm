package Redis::Namespace;

use strict;
use warnings;
our $VERSION = '0.14';

use Redis;
use Carp qw(carp croak);

# the before filter that does nothing
my $NOOP = sub {
    my ($self, @args) = @_;
    return @args;
};

sub add_namespace {
    my ($self, @args) = @_;
    my $namespace = $self->{namespace};
    return @args unless $namespace;

    my @result;
    for my $item(@args) {
        my $type = ref $item;
        if($item && !$type) {
            push @result, "$namespace:$item";
        } elsif($type eq 'SCALAR') {
            push @result, \"$namespace:$$item";
        } elsif($type eq 'ARRAY') {
            push @result, [$self->add_namespace(@$item)];
        } elsif($type eq 'HASH') {
            my %hash;
            while (my ($key, $value) = each %$item) {
                my ($new_key) = $self->add_namespace($key);
                $hash{$new_key} = $value;
            }
            push @result, \%hash;
        } else {
            push @result, $item;
        }
    }
    return @result;
}

sub rem_namespace {
    my ($self, @args) = @_;
    my $namespace = $self->{namespace};
    return @args unless $namespace;

    my @result;
    for my $item(@args) {
        my $type = ref $item;
        if($item && !$type) {
            $item =~ s/^\Q$namespace://;
            push @result, $item;
        } elsif($type eq 'SCALAR') {
            my $tmp = $$item;
            $tmp =~ s/^\Q$namespace://;
            push @result, \$tmp;
        } elsif($type eq 'ARRAY') {
            push @result, [$self->rem_namespace(@$item)];
        } elsif($type eq 'HASH') {
            my %hash;
            while (my ($key, $value) = each %$item) {
                my ($new_key) = $self->rem_namespace($key);
                $hash{$new_key} = $value;
            }
            push @result, \%hash;
        } else {
            push @result, $item;
        }
    }
    return @result;
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self  = bless {}, $class;

    $self->{redis} = $args{redis} || Redis->new(%args);
    $self->{namespace} = $args{namespace};
    $self->{warning} = $args{warning};
    $self->{strict} = $args{strict};
    $self->{subscribers} = {};
    if ($args{guess}) {
        my $count = eval { $self->{redis}->command_count };
        if ($count) {
            $self->{guess} = 1;
        } elsif ($self->{warning}) {
            my $version = $self->{redis}->info->{redis_version};
            carp "guess option requires 2.8.13 or later. your redis version is $version";
        }
    }
    $self->{guess_cache} = {};
    $self->{movablekeys} = {};

    # escape for pattern
    my $escaped = $args{namespace};
    $escaped =~ s/([[?*\\])/"\\$1"/ge;
    $self->{namespace_escaped} = $escaped;

    return $self;
}

sub _guess {
    my ($self, $command, @args) = @_;
    if (!$self->{guess}) {
        carp "unknown command '$command'. passing arguments to the redis server as is.";
        return $NOOP;
    }

    if (my $cache = $self->{guess_cache}{$command}) {
        return $cache;
    }

    my $movablekeys = $self->{movablekeys}{$command};
    if ($movablekeys) {
        return $self->_guess_movablekeys($command, @args);
    }

    my $info = $self->{redis}->command_info($command);
    my ($name, $num, $flags, $first, $last, $step) = @{$info->[0] || []};

    unless ($name) {
        if ($self->{warning}) {
            carp "unknown command '$command'. passing arguments to the redis server as is.";
        }
        $self->{guess_cache}{$command} = $NOOP;
        return $NOOP;
    }

    ($movablekeys) = grep { $_ eq 'movablekeys' } @{$flags || []};
    if ($movablekeys) {
        $self->{movablekeys}{$command} = 1;
        return $self->_guess_movablekeys($command, @args);
    }

    my $before = sub {
        my ($self, @args) = @_;
        if ($first > 0) {
            for (my $i = $first; $i <= @args && ($last < 0 || $i <= $last); $i += $step) {
                ($args[$i-1]) = $self->add_namespace($args[$i-1]);
            }
        }
        return @args;
    };
    $self->{guess_cache}{$command} = $before;
    return $before;
}

sub _guess_movablekeys {
    my ($self, $command, @args) = @_;
    if(@args && ref $args[-1] eq 'CODE') {
        pop @args; # ignore callback function
    }

    my @keys = eval { $self->{redis}->command_getkeys($command, @args) }
        or return $NOOP;
    my @positions = ();
    my @list = ();

    # search the positions of keys.
    my $search; $search = sub {
        my ($i, $start) = @_;
        my $key = $keys[$i];
        for (my $j = $start; $j < @args; $j++) {
            next if $args[$j] ne $key;
            push @positions, $j;
            if ($i+1 < @keys) {
                $search->($i+1, $j+1);
            } else {
                push @list, [@positions];
            }
            pop @positions;
        }
    };
    $search->(0, 0);

    if (@list == 0) {
        croak "fail to guess key positions of command '$command'";
    } elsif (@list == 1) {
        # found keys
        my $positions = $list[0];
        return sub {
            my ($self, @args) = @_;
            @args[@$positions] = $self->add_namespace(@args[@$positions]);
            return @args;
        };
    }

    # found keys, but their positions are ambiguous
    my $prefix = "test-key-$^T-$$-";
    my @want = map { "$prefix$_" } @keys;
LOOP:
    for my $positions(@list) {
        my @args = @args;
        for my $i(@$positions) {
            $args[$i] = $prefix . $args[$i];
        }
        my @keys = eval { $self->{redis}->command_getkeys($command, @args) };

        if (scalar(@keys) != scalar(@want)) {
            next;
        }
        for my $i(0..scalar(@keys)-1) {
            if ($keys[$i] ne $want[$i]) {
                next LOOP
            }
        }

        # found!
        return sub {
            my ($self, @args) = @_;
            @args[@$positions] = $self->add_namespace(@args[@$positions]);
            return @args;
        };
    }

    croak "fail to guess key positions of command '$command'";
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    my $command = $AUTOLOAD;
    $command =~ s/.*://;

    # the method names are case-insensitive. e.g. $ns->GET('key')
    my $method = __PACKAGE__->can(lc $command) || sub {
        my ($self, @args) = @_;
        return $self->_call_unknown_command($command, @args);
    };

    # Save this method for future calls
    no strict 'refs';
    *$AUTOLOAD = $method;

    goto $method;
}

# call the command that is not defined in the generated commands.
sub _call_unknown_command {
    my ($self, $command, @args) = @_;
    croak "unknown command '$command'" if $self->{strict};

    my ($cmd, @extra) = split /_/, lc $command;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;
    my $before = $self->_guess($command, @extra, @args);
    @args = $before->($self, @extra, @args);
    push @args, $cb if $cb;
    return $self->{redis}->$cmd(@args);
}

# more convenient scan interface

sub scan_callback {
    my ($self, @args) = @_;
    my $callback = pop @args;

    croak "last argument to scan_callback must be a callback"
        unless ref $callback eq 'CODE';
    croak "arguments to scan_callback must be a hash, not odd-sized array"
        if @args % 2;

    my $iter = 0;
    do {
        ($iter, my $list) = $self->scan($iter, @args);
        foreach my $key(@$list) {
            $callback->($key);
        };
    } while ($iter);
}

# special commands. they are not redis commands.
sub wait_one_response {
    my $self = shift;
    return $self->{redis}->wait_one_response(@_);
}
sub wait_all_responses {
    my $self = shift;
    return $self->{redis}->wait_all_responses(@_);
}

sub __wrap_subcb {
    my ($self, $cb) = @_;
    my $subscribers = $self->{subscribers};
    my $callback = $subscribers->{$cb} // sub {
        my ($message, $topic, $subscribed_topic) = @_;
        $cb->($message, $self->rem_namespace($topic), $self->rem_namespace($subscribed_topic));
    };
    $subscribers->{$cb} = $callback;
    return $callback;
}

sub __subscribe {
    my ($self, $command, @args) = @_;
    my $cb = pop @args;
    confess("missing required callback in call to $command(), ")
        unless ref($cb) eq 'CODE';

    my $redis = $self->{redis};
    my $callback = $self->__wrap_subcb($cb);
    @args = $self->add_namespace(@args);
    return $redis->$command(@args, $callback);
}

sub __psubscribe {
    my ($self, $command, @args) = @_;
    my $cb = pop @args;
    confess("missing required callback in call to $command(), ")
        unless ref($cb) eq 'CODE';

    my $redis = $self->{redis};
    my $callback = $self->__wrap_subcb($cb);
    my $namespace = $self->{namespace_escaped};
    @args = map { "$namespace:$_" } @args;
    return $redis->$command(@args, $callback);
}

# PubSub commands
sub wait_for_messages {
    my $self = shift;
    return $self->{redis}->wait_for_messages(@_);
}

sub is_subscriber {
    my $self = shift;
    return $self->{redis}->is_subscriber(@_);
}

sub subscribe {
    my $self = shift;
    return $self->__subscribe('subscribe', @_);
}

sub psubscribe {
    my $self = shift;
    return $self->__psubscribe('psubscribe', @_);
}

sub unsubscribe {
    my $self = shift;
    return $self->__subscribe('unsubscribe', @_);
}

sub punsubscribe {
    my $self = shift;
    return $self->__psubscribe('punsubscribe', @_);
}

# BEGIN GENERATED COMMANDS
# This section is generated by author/generate_commands.pl from
# - https://raw.githubusercontent.com/redis/docs/refs/heads/main/data/commands.json
# - https://github.com/valkey-io/valkey/tree/9.1.2/src/commands
# DO NOT EDIT.

## no critic (Subroutines::ProhibitBuiltinHomonyms)

# ACL
sub acl {
    my ($self, @args) = @_;
    return $self->{redis}->acl(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'cat' ||
        $subcommand eq 'dryrun' ||
        $subcommand eq 'genpass' ||
        $subcommand eq 'getuser' ||
        $subcommand eq 'help' ||
        $subcommand eq 'list' ||
        $subcommand eq 'log' ||
        $subcommand eq 'users' ||
        $subcommand eq 'whoami'
    ) {
        return $self->{redis}->acl(@args);
    }

    # ACL DELUSER
    if ($subcommand eq 'deluser') {
        croak "unsafe command 'acl deluser'" if $self->{strict};
        return $self->{redis}->acl(@args);
    }

    # ACL LOAD
    if ($subcommand eq 'load') {
        croak "unsafe command 'acl load'" if $self->{strict};
        return $self->{redis}->acl(@args);
    }

    # ACL SAVE
    if ($subcommand eq 'save') {
        croak "unsafe command 'acl save'" if $self->{strict};
        return $self->{redis}->acl(@args);
    }

    # ACL SETUSER
    if ($subcommand eq 'setuser') {
        croak "unsafe command 'acl setuser'" if $self->{strict};
        return $self->{redis}->acl(@args);
    }

    croak "unknown command 'acl $args[0]'" if $self->{strict};
    carp "unknown command 'acl $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->acl(@args);
}

# ACL CAT
sub acl_cat {
    my ($self, @args) = @_;
    return $self->{redis}->acl_cat(@args);
}

# ACL DELUSER
sub acl_deluser {
    my ($self, @args) = @_;
    croak "unsafe command 'acl deluser'" if $self->{strict};
    return $self->{redis}->acl_deluser(@args);
}

# ACL DRYRUN
sub acl_dryrun {
    my ($self, @args) = @_;
    return $self->{redis}->acl_dryrun(@args);
}

# ACL GENPASS
sub acl_genpass {
    my ($self, @args) = @_;
    return $self->{redis}->acl_genpass(@args);
}

# ACL GETUSER
sub acl_getuser {
    my ($self, @args) = @_;
    return $self->{redis}->acl_getuser(@args);
}

# ACL HELP
sub acl_help {
    my ($self, @args) = @_;
    return $self->{redis}->acl_help(@args);
}

# ACL LIST
sub acl_list {
    my ($self, @args) = @_;
    return $self->{redis}->acl_list(@args);
}

# ACL LOAD
sub acl_load {
    my ($self, @args) = @_;
    croak "unsafe command 'acl load'" if $self->{strict};
    return $self->{redis}->acl_load(@args);
}

# ACL LOG
sub acl_log {
    my ($self, @args) = @_;
    return $self->{redis}->acl_log(@args);
}

# ACL SAVE
sub acl_save {
    my ($self, @args) = @_;
    croak "unsafe command 'acl save'" if $self->{strict};
    return $self->{redis}->acl_save(@args);
}

# ACL SETUSER
sub acl_setuser {
    my ($self, @args) = @_;
    croak "unsafe command 'acl setuser'" if $self->{strict};
    return $self->{redis}->acl_setuser(@args);
}

# ACL USERS
sub acl_users {
    my ($self, @args) = @_;
    return $self->{redis}->acl_users(@args);
}

# ACL WHOAMI
sub acl_whoami {
    my ($self, @args) = @_;
    return $self->{redis}->acl_whoami(@args);
}

# APPEND
sub append {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->append(@args);
}

# ARCOUNT
sub arcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arcount(@args);
}

# ARDEL
sub ardel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->ardel(@args);
}

# ARDELRANGE
sub ardelrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->ardelrange(@args);
}

# ARGET
sub arget {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arget(@args);
}

# ARGETRANGE
sub argetrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->argetrange(@args);
}

# ARGREP
sub argrep {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->argrep(@args);
}

# ARINFO
sub arinfo {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arinfo(@args);
}

# ARINSERT
sub arinsert {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arinsert(@args);
}

# ARLASTITEMS
sub arlastitems {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arlastitems(@args);
}

# ARLEN
sub arlen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arlen(@args);
}

# ARMGET
sub armget {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->armget(@args);
}

# ARMSET
sub armset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->armset(@args);
}

# ARNEXT
sub arnext {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arnext(@args);
}

# AROP
sub arop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arop(@args);
}

# ARRING
sub arring {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arring(@args);
}

# ARSCAN
sub arscan {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arscan(@args);
}

# ARSEEK
sub arseek {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arseek(@args);
}

# ARSET
sub arset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->arset(@args);
}

# ASKING
sub asking {
    my ($self, @args) = @_;
    return $self->{redis}->asking(@args);
}

# AUTH
sub auth {
    my ($self, @args) = @_;
    return $self->{redis}->auth(@args);
}

# BACKUP
sub backup {
    my ($self, @args) = @_;
    return $self->{redis}->backup(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'abort' ||
        $subcommand eq 'cleanup' ||
        $subcommand eq 'help' ||
        $subcommand eq 'list' ||
        $subcommand eq 'seal' ||
        $subcommand eq 'start' ||
        $subcommand eq 'status'
    ) {
        return $self->{redis}->backup(@args);
    }

    croak "unknown command 'backup $args[0]'" if $self->{strict};
    carp "unknown command 'backup $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->backup(@args);
}

# BACKUP ABORT
sub backup_abort {
    my ($self, @args) = @_;
    return $self->{redis}->backup_abort(@args);
}

# BACKUP CLEANUP
sub backup_cleanup {
    my ($self, @args) = @_;
    return $self->{redis}->backup_cleanup(@args);
}

# BACKUP HELP
sub backup_help {
    my ($self, @args) = @_;
    return $self->{redis}->backup_help(@args);
}

# BACKUP LIST
sub backup_list {
    my ($self, @args) = @_;
    return $self->{redis}->backup_list(@args);
}

# BACKUP SEAL
sub backup_seal {
    my ($self, @args) = @_;
    return $self->{redis}->backup_seal(@args);
}

# BACKUP START
sub backup_start {
    my ($self, @args) = @_;
    return $self->{redis}->backup_start(@args);
}

# BACKUP STATUS
sub backup_status {
    my ($self, @args) = @_;
    return $self->{redis}->backup_status(@args);
}

# BGREWRITEAOF
sub bgrewriteaof {
    my ($self, @args) = @_;
    return $self->{redis}->bgrewriteaof(@args);
}

# BGSAVE
sub bgsave {
    my ($self, @args) = @_;
    return $self->{redis}->bgsave(@args);
}

# BITCOUNT
sub bitcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bitcount(@args);
}

# BITFIELD
sub bitfield {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bitfield(@args);
}

# BITOP
sub bitop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 1) {
        push @positions, 1;
    }
    for (my $i = 2; $i < @args; $i++) {
        push @positions, $i;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bitop(@args);
}

# BITPOS
sub bitpos {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bitpos(@args);
}

# BLESS
sub bless {
    my ($self, @args) = @_;
    return $self->{redis}->bless(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # BLESS CLEAR, BLESS GET, BLESS SET
    if (
        $subcommand eq 'clear' ||
        $subcommand eq 'get' ||
        $subcommand eq 'set'
    ) {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->bless($name, @args);
    }

    # BLESS SCAN
    if ($subcommand eq 'scan') {
        return $self->{redis}->bless(@args);
    }

    croak "unknown command 'bless $args[0]'" if $self->{strict};
    carp "unknown command 'bless $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->bless(@args);
}

# BLESS CLEAR
sub bless_clear {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bless_clear(@args);
}

# BLESS GET
sub bless_get {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bless_get(@args);
}

# BLESS SCAN
sub bless_scan {
    my ($self, @args) = @_;
    return $self->{redis}->bless_scan(@args);
}

# BLESS SET
sub bless_set {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->bless_set(@args);
}

# BLMOVE
sub blmove {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->blmove(@args);
}

# BLMOVEM
sub blmovem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->blmovem(@args);
}

# BLMPOP
sub blmpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[1];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->blmpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->blmpop(@args)) if wantarray;
    my $result = $self->{redis}->blmpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# BLPOP
sub blpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args - 1; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->blpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->blpop(@args)) if wantarray;
    my $result = $self->{redis}->blpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# BRPOP
sub brpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args - 1; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->brpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->brpop(@args)) if wantarray;
    my $result = $self->{redis}->brpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# BRPOPLPUSH
sub brpoplpush {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->brpoplpush(@args);
}

# BZMPOP
sub bzmpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[1];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->bzmpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->bzmpop(@args)) if wantarray;
    my $result = $self->{redis}->bzmpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# BZPOPMAX
sub bzpopmax {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args - 1; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->bzpopmax(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->bzpopmax(@args)) if wantarray;
    my $result = $self->{redis}->bzpopmax(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# BZPOPMIN
sub bzpopmin {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args - 1; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->bzpopmin(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->bzpopmin(@args)) if wantarray;
    my $result = $self->{redis}->bzpopmin(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# CLIENT
sub client {
    my ($self, @args) = @_;
    return $self->{redis}->client(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'caching' ||
        $subcommand eq 'capa' ||
        $subcommand eq 'getname' ||
        $subcommand eq 'getredir' ||
        $subcommand eq 'help' ||
        $subcommand eq 'id' ||
        $subcommand eq 'import-source' ||
        $subcommand eq 'info' ||
        $subcommand eq 'kill' ||
        $subcommand eq 'list' ||
        $subcommand eq 'no-evict' ||
        $subcommand eq 'no-touch' ||
        $subcommand eq 'pause' ||
        $subcommand eq 'reply' ||
        $subcommand eq 'setinfo' ||
        $subcommand eq 'setname' ||
        $subcommand eq 'tracking' ||
        $subcommand eq 'trackinginfo' ||
        $subcommand eq 'unblock' ||
        $subcommand eq 'unpause'
    ) {
        return $self->{redis}->client(@args);
    }

    croak "unknown command 'client $args[0]'" if $self->{strict};
    carp "unknown command 'client $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->client(@args);
}

# CLIENT CACHING
sub client_caching {
    my ($self, @args) = @_;
    return $self->{redis}->client_caching(@args);
}

# CLIENT CAPA
sub client_capa {
    my ($self, @args) = @_;
    return $self->{redis}->client_capa(@args);
}

# CLIENT GETNAME
sub client_getname {
    my ($self, @args) = @_;
    return $self->{redis}->client_getname(@args);
}

# CLIENT GETREDIR
sub client_getredir {
    my ($self, @args) = @_;
    return $self->{redis}->client_getredir(@args);
}

# CLIENT HELP
sub client_help {
    my ($self, @args) = @_;
    return $self->{redis}->client_help(@args);
}

# CLIENT ID
sub client_id {
    my ($self, @args) = @_;
    return $self->{redis}->client_id(@args);
}

# CLIENT INFO
sub client_info {
    my ($self, @args) = @_;
    return $self->{redis}->client_info(@args);
}

# CLIENT KILL
sub client_kill {
    my ($self, @args) = @_;
    return $self->{redis}->client_kill(@args);
}

# CLIENT LIST
sub client_list {
    my ($self, @args) = @_;
    return $self->{redis}->client_list(@args);
}

# CLIENT PAUSE
sub client_pause {
    my ($self, @args) = @_;
    return $self->{redis}->client_pause(@args);
}

# CLIENT REPLY
sub client_reply {
    my ($self, @args) = @_;
    return $self->{redis}->client_reply(@args);
}

# CLIENT SETINFO
sub client_setinfo {
    my ($self, @args) = @_;
    return $self->{redis}->client_setinfo(@args);
}

# CLIENT SETNAME
sub client_setname {
    my ($self, @args) = @_;
    return $self->{redis}->client_setname(@args);
}

# CLIENT TRACKING
sub client_tracking {
    my ($self, @args) = @_;
    return $self->{redis}->client_tracking(@args);
}

# CLIENT TRACKINGINFO
sub client_trackinginfo {
    my ($self, @args) = @_;
    return $self->{redis}->client_trackinginfo(@args);
}

# CLIENT UNBLOCK
sub client_unblock {
    my ($self, @args) = @_;
    return $self->{redis}->client_unblock(@args);
}

# CLIENT UNPAUSE
sub client_unpause {
    my ($self, @args) = @_;
    return $self->{redis}->client_unpause(@args);
}

# CLUSTER
sub cluster {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'addslots' ||
        $subcommand eq 'addslotsrange' ||
        $subcommand eq 'bumpepoch' ||
        $subcommand eq 'cancelslotmigrations' ||
        $subcommand eq 'count-failure-reports' ||
        $subcommand eq 'countkeysinslot' ||
        $subcommand eq 'delslots' ||
        $subcommand eq 'delslotsrange' ||
        $subcommand eq 'failover' ||
        $subcommand eq 'flushslot' ||
        $subcommand eq 'flushslots' ||
        $subcommand eq 'forget' ||
        $subcommand eq 'getkeysinslot' ||
        $subcommand eq 'getslotmigrations' ||
        $subcommand eq 'help' ||
        $subcommand eq 'info' ||
        $subcommand eq 'keyslot' ||
        $subcommand eq 'links' ||
        $subcommand eq 'meet' ||
        $subcommand eq 'migrateslots' ||
        $subcommand eq 'migration' ||
        $subcommand eq 'myid' ||
        $subcommand eq 'myshardid' ||
        $subcommand eq 'nodes' ||
        $subcommand eq 'replicas' ||
        $subcommand eq 'replicate' ||
        $subcommand eq 'reset' ||
        $subcommand eq 'saveconfig' ||
        $subcommand eq 'set-config-epoch' ||
        $subcommand eq 'setslot' ||
        $subcommand eq 'shards' ||
        $subcommand eq 'slaves' ||
        $subcommand eq 'slot-stats' ||
        $subcommand eq 'slots' ||
        $subcommand eq 'syncslots'
    ) {
        return $self->{redis}->cluster(@args);
    }

    croak "unknown command 'cluster $args[0]'" if $self->{strict};
    carp "unknown command 'cluster $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->cluster(@args);
}

# CLUSTER ADDSLOTS
sub cluster_addslots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_addslots(@args);
}

# CLUSTER ADDSLOTSRANGE
sub cluster_addslotsrange {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_addslotsrange(@args);
}

# CLUSTER BUMPEPOCH
sub cluster_bumpepoch {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_bumpepoch(@args);
}

# CLUSTER CANCELSLOTMIGRATIONS
sub cluster_cancelslotmigrations {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_cancelslotmigrations(@args);
}

# CLUSTER COUNTKEYSINSLOT
sub cluster_countkeysinslot {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_countkeysinslot(@args);
}

# CLUSTER DELSLOTS
sub cluster_delslots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_delslots(@args);
}

# CLUSTER DELSLOTSRANGE
sub cluster_delslotsrange {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_delslotsrange(@args);
}

# CLUSTER FAILOVER
sub cluster_failover {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_failover(@args);
}

# CLUSTER FLUSHSLOT
sub cluster_flushslot {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_flushslot(@args);
}

# CLUSTER FLUSHSLOTS
sub cluster_flushslots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_flushslots(@args);
}

# CLUSTER FORGET
sub cluster_forget {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_forget(@args);
}

# CLUSTER GETKEYSINSLOT
sub cluster_getkeysinslot {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_getkeysinslot(@args);
}

# CLUSTER GETSLOTMIGRATIONS
sub cluster_getslotmigrations {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_getslotmigrations(@args);
}

# CLUSTER HELP
sub cluster_help {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_help(@args);
}

# CLUSTER INFO
sub cluster_info {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_info(@args);
}

# CLUSTER KEYSLOT
sub cluster_keyslot {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_keyslot(@args);
}

# CLUSTER LINKS
sub cluster_links {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_links(@args);
}

# CLUSTER MEET
sub cluster_meet {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_meet(@args);
}

# CLUSTER MIGRATESLOTS
sub cluster_migrateslots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_migrateslots(@args);
}

# CLUSTER MIGRATION
sub cluster_migration {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_migration(@args);
}

# CLUSTER MYID
sub cluster_myid {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_myid(@args);
}

# CLUSTER MYSHARDID
sub cluster_myshardid {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_myshardid(@args);
}

# CLUSTER NODES
sub cluster_nodes {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_nodes(@args);
}

# CLUSTER REPLICAS
sub cluster_replicas {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_replicas(@args);
}

# CLUSTER REPLICATE
sub cluster_replicate {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_replicate(@args);
}

# CLUSTER RESET
sub cluster_reset {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_reset(@args);
}

# CLUSTER SAVECONFIG
sub cluster_saveconfig {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_saveconfig(@args);
}

# CLUSTER SETSLOT
sub cluster_setslot {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_setslot(@args);
}

# CLUSTER SHARDS
sub cluster_shards {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_shards(@args);
}

# CLUSTER SLAVES
sub cluster_slaves {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_slaves(@args);
}

# CLUSTER SLOTS
sub cluster_slots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_slots(@args);
}

# CLUSTER SYNCSLOTS
sub cluster_syncslots {
    my ($self, @args) = @_;
    croak "unsafe command 'cluster'" if $self->{strict};
    return $self->{redis}->cluster_syncslots(@args);
}

# COMMAND
sub command {
    my ($self, @args) = @_;
    return $self->{redis}->command(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'count' ||
        $subcommand eq 'docs' ||
        $subcommand eq 'getkeys' ||
        $subcommand eq 'getkeysandflags' ||
        $subcommand eq 'help' ||
        $subcommand eq 'info' ||
        $subcommand eq 'list'
    ) {
        return $self->{redis}->command(@args);
    }

    croak "unknown command 'command $args[0]'" if $self->{strict};
    carp "unknown command 'command $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->command(@args);
}

# COMMAND COUNT
sub command_count {
    my ($self, @args) = @_;
    return $self->{redis}->command_count(@args);
}

# COMMAND DOCS
sub command_docs {
    my ($self, @args) = @_;
    return $self->{redis}->command_docs(@args);
}

# COMMAND GETKEYS
sub command_getkeys {
    my ($self, @args) = @_;
    return $self->{redis}->command_getkeys(@args);
}

# COMMAND GETKEYSANDFLAGS
sub command_getkeysandflags {
    my ($self, @args) = @_;
    return $self->{redis}->command_getkeysandflags(@args);
}

# COMMAND HELP
sub command_help {
    my ($self, @args) = @_;
    return $self->{redis}->command_help(@args);
}

# COMMAND INFO
sub command_info {
    my ($self, @args) = @_;
    return $self->{redis}->command_info(@args);
}

# COMMAND LIST
sub command_list {
    my ($self, @args) = @_;
    return $self->{redis}->command_list(@args);
}

# COMMANDLOG
sub commandlog {
    my ($self, @args) = @_;
    return $self->{redis}->commandlog(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'get' ||
        $subcommand eq 'help' ||
        $subcommand eq 'len' ||
        $subcommand eq 'reset'
    ) {
        return $self->{redis}->commandlog(@args);
    }

    croak "unknown command 'commandlog $args[0]'" if $self->{strict};
    carp "unknown command 'commandlog $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->commandlog(@args);
}

# COMMANDLOG GET
sub commandlog_get {
    my ($self, @args) = @_;
    return $self->{redis}->commandlog_get(@args);
}

# COMMANDLOG HELP
sub commandlog_help {
    my ($self, @args) = @_;
    return $self->{redis}->commandlog_help(@args);
}

# COMMANDLOG LEN
sub commandlog_len {
    my ($self, @args) = @_;
    return $self->{redis}->commandlog_len(@args);
}

# COMMANDLOG RESET
sub commandlog_reset {
    my ($self, @args) = @_;
    return $self->{redis}->commandlog_reset(@args);
}

# CONFIG
sub config {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'get' ||
        $subcommand eq 'help' ||
        $subcommand eq 'resetstat' ||
        $subcommand eq 'rewrite' ||
        $subcommand eq 'set'
    ) {
        return $self->{redis}->config(@args);
    }

    croak "unknown command 'config $args[0]'" if $self->{strict};
    carp "unknown command 'config $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->config(@args);
}

# CONFIG GET
sub config_get {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config_get(@args);
}

# CONFIG HELP
sub config_help {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config_help(@args);
}

# CONFIG RESETSTAT
sub config_resetstat {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config_resetstat(@args);
}

# CONFIG REWRITE
sub config_rewrite {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config_rewrite(@args);
}

# CONFIG SET
sub config_set {
    my ($self, @args) = @_;
    croak "unsafe command 'config'" if $self->{strict};
    return $self->{redis}->config_set(@args);
}

# COPY
sub copy {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->copy(@args);
}

# DBSIZE
sub dbsize {
    my ($self, @args) = @_;
    return $self->{redis}->dbsize(@args);
}

# DEBUG
sub debug {
    my ($self, @args) = @_;
    return $self->{redis}->debug(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # DEBUG OBJECT
    if ($subcommand eq 'object') {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->debug($name, @args);
    }

    croak "unknown command 'debug $args[0]'" if $self->{strict};
    carp "unknown command 'debug $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->debug(@args);
}

# DEBUG OBJECT
sub debug_object {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->debug_object(@args);
}

# DECR
sub decr {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->decr(@args);
}

# DECRBY
sub decrby {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->decrby(@args);
}

# DEL
sub del {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->del(@args);
}

# DELEX
sub delex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->delex(@args);
}

# DELIFEQ
sub delifeq {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->delifeq(@args);
}

# DIGEST
sub digest {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->digest(@args);
}

# DISCARD
sub discard {
    my ($self, @args) = @_;
    return $self->{redis}->discard(@args);
}

# DUMP
sub dump {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->dump(@args);
}

# ECHO
sub echo {
    my ($self, @args) = @_;
    return $self->{redis}->echo(@args);
}

# EVAL
sub eval {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[1];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->eval(@args);
}

# EVALSHA
sub evalsha {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[1];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->evalsha(@args);
}

# EXEC
sub exec {
    my ($self, @args) = @_;
    return $self->{redis}->exec(@args);
}

# EXISTS
sub exists {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->exists(@args);
}

# EXPIRE
sub expire {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->expire(@args);
}

# EXPIREAT
sub expireat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->expireat(@args);
}

# EXPIRETIME
sub expiretime {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->expiretime(@args);
}

# FAILOVER
sub failover {
    my ($self, @args) = @_;
    croak "unsafe command 'failover'" if $self->{strict};
    return $self->{redis}->failover(@args);
}

# FCALL
sub fcall {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[1];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->fcall(@args);
}

# FLUSHALL
sub flushall {
    my ($self, @args) = @_;
    croak "unsafe command 'flushall'" if $self->{strict};
    return $self->{redis}->flushall(@args);
}

# FLUSHDB
sub flushdb {
    my ($self, @args) = @_;
    croak "unsafe command 'flushdb'" if $self->{strict};
    return $self->{redis}->flushdb(@args);
}

# FUNCTION
sub function {
    my ($self, @args) = @_;
    return $self->{redis}->function(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # FUNCTION DELETE
    if ($subcommand eq 'delete') {
        croak "unsafe command 'function delete'" if $self->{strict};
        return $self->{redis}->function(@args);
    }

    if (
        $subcommand eq 'dump' ||
        $subcommand eq 'help' ||
        $subcommand eq 'kill' ||
        $subcommand eq 'list' ||
        $subcommand eq 'load' ||
        $subcommand eq 'stats'
    ) {
        return $self->{redis}->function(@args);
    }

    # FUNCTION FLUSH
    if ($subcommand eq 'flush') {
        croak "unsafe command 'function flush'" if $self->{strict};
        return $self->{redis}->function(@args);
    }

    # FUNCTION RESTORE
    if ($subcommand eq 'restore') {
        croak "unsafe command 'function restore'" if $self->{strict};
        return $self->{redis}->function(@args);
    }

    croak "unknown command 'function $args[0]'" if $self->{strict};
    carp "unknown command 'function $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->function(@args);
}

# FUNCTION DELETE
sub function_delete {
    my ($self, @args) = @_;
    croak "unsafe command 'function delete'" if $self->{strict};
    return $self->{redis}->function_delete(@args);
}

# FUNCTION DUMP
sub function_dump {
    my ($self, @args) = @_;
    return $self->{redis}->function_dump(@args);
}

# FUNCTION FLUSH
sub function_flush {
    my ($self, @args) = @_;
    croak "unsafe command 'function flush'" if $self->{strict};
    return $self->{redis}->function_flush(@args);
}

# FUNCTION HELP
sub function_help {
    my ($self, @args) = @_;
    return $self->{redis}->function_help(@args);
}

# FUNCTION KILL
sub function_kill {
    my ($self, @args) = @_;
    return $self->{redis}->function_kill(@args);
}

# FUNCTION LIST
sub function_list {
    my ($self, @args) = @_;
    return $self->{redis}->function_list(@args);
}

# FUNCTION LOAD
sub function_load {
    my ($self, @args) = @_;
    return $self->{redis}->function_load(@args);
}

# FUNCTION RESTORE
sub function_restore {
    my ($self, @args) = @_;
    croak "unsafe command 'function restore'" if $self->{strict};
    return $self->{redis}->function_restore(@args);
}

# FUNCTION STATS
sub function_stats {
    my ($self, @args) = @_;
    return $self->{redis}->function_stats(@args);
}

# GEOADD
sub geoadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geoadd(@args);
}

# GEODIST
sub geodist {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geodist(@args);
}

# GEOHASH
sub geohash {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geohash(@args);
}

# GEOPOS
sub geopos {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geopos(@args);
}

# GEORADIUS
sub georadius {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    {
        my $first;
        for (my $i = 5; $i < @args; $i++) {
            if (lc($args[$i] // '') eq 'store') {
                $first = $i + 1;
                last;
            }
        }
        if (defined $first) {
            if (@args > $first) {
                push @positions, $first;
            }
        }
    }
    {
        my $first;
        for (my $i = 5; $i < @args; $i++) {
            if (lc($args[$i] // '') eq 'storedist') {
                $first = $i + 1;
                last;
            }
        }
        if (defined $first) {
            if (@args > $first) {
                push @positions, $first;
            }
        }
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->georadius(@args);
}

# GEORADIUSBYMEMBER
sub georadiusbymember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    {
        my $first;
        for (my $i = 4; $i < @args; $i++) {
            if (lc($args[$i] // '') eq 'store') {
                $first = $i + 1;
                last;
            }
        }
        if (defined $first) {
            if (@args > $first) {
                push @positions, $first;
            }
        }
    }
    {
        my $first;
        for (my $i = 4; $i < @args; $i++) {
            if (lc($args[$i] // '') eq 'storedist') {
                $first = $i + 1;
                last;
            }
        }
        if (defined $first) {
            if (@args > $first) {
                push @positions, $first;
            }
        }
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->georadiusbymember(@args);
}

# GEOSEARCH
sub geosearch {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geosearch(@args);
}

# GEOSEARCHSTORE
sub geosearchstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->geosearchstore(@args);
}

# GET
sub get {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->get(@args);
}

# GETBIT
sub getbit {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->getbit(@args);
}

# GETDEL
sub getdel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->getdel(@args);
}

# GETEX
sub getex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->getex(@args);
}

# GETRANGE
sub getrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->getrange(@args);
}

# GETSET
sub getset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->getset(@args);
}

# HDEL
sub hdel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hdel(@args);
}

# HELLO
sub hello {
    my ($self, @args) = @_;
    return $self->{redis}->hello(@args);
}

# HEXISTS
sub hexists {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hexists(@args);
}

# HEXPIRE
sub hexpire {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hexpire(@args);
}

# HEXPIREAT
sub hexpireat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hexpireat(@args);
}

# HEXPIRETIME
sub hexpiretime {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hexpiretime(@args);
}

# HGET
sub hget {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hget(@args);
}

# HGETALL
sub hgetall {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hgetall(@args);
}

# HGETDEL
sub hgetdel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hgetdel(@args);
}

# HGETEX
sub hgetex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hgetex(@args);
}

# HIMPORT
sub himport {
    my ($self, @args) = @_;
    return $self->{redis}->himport(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # HIMPORT DISCARD, HIMPORT DISCARDALL, HIMPORT PREPARE
    if (
        $subcommand eq 'discard' ||
        $subcommand eq 'discardall' ||
        $subcommand eq 'prepare'
    ) {
        return $self->{redis}->himport(@args);
    }

    # HIMPORT SET
    if ($subcommand eq 'set') {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->himport($name, @args);
    }

    croak "unknown command 'himport $args[0]'" if $self->{strict};
    carp "unknown command 'himport $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->himport(@args);
}

# HIMPORT DISCARD
sub himport_discard {
    my ($self, @args) = @_;
    return $self->{redis}->himport_discard(@args);
}

# HIMPORT DISCARDALL
sub himport_discardall {
    my ($self, @args) = @_;
    return $self->{redis}->himport_discardall(@args);
}

# HIMPORT PREPARE
sub himport_prepare {
    my ($self, @args) = @_;
    return $self->{redis}->himport_prepare(@args);
}

# HIMPORT SET
sub himport_set {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->himport_set(@args);
}

# HINCRBY
sub hincrby {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hincrby(@args);
}

# HINCRBYFLOAT
sub hincrbyfloat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hincrbyfloat(@args);
}

# HKEYS
sub hkeys {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hkeys(@args);
}

# HLEN
sub hlen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hlen(@args);
}

# HMGET
sub hmget {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hmget(@args);
}

# HMSET
sub hmset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hmset(@args);
}

# HOTKEYS
sub hotkeys {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'get' ||
        $subcommand eq 'help' ||
        $subcommand eq 'reset' ||
        $subcommand eq 'start' ||
        $subcommand eq 'stop'
    ) {
        return $self->{redis}->hotkeys(@args);
    }

    croak "unknown command 'hotkeys $args[0]'" if $self->{strict};
    carp "unknown command 'hotkeys $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->hotkeys(@args);
}

# HOTKEYS GET
sub hotkeys_get {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys_get(@args);
}

# HOTKEYS HELP
sub hotkeys_help {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys_help(@args);
}

# HOTKEYS RESET
sub hotkeys_reset {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys_reset(@args);
}

# HOTKEYS START
sub hotkeys_start {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys_start(@args);
}

# HOTKEYS STOP
sub hotkeys_stop {
    my ($self, @args) = @_;
    return $self->{redis}->hotkeys_stop(@args);
}

# HPERSIST
sub hpersist {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hpersist(@args);
}

# HPEXPIRE
sub hpexpire {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hpexpire(@args);
}

# HPEXPIREAT
sub hpexpireat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hpexpireat(@args);
}

# HPEXPIRETIME
sub hpexpiretime {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hpexpiretime(@args);
}

# HPTTL
sub hpttl {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hpttl(@args);
}

# HRANDFIELD
sub hrandfield {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hrandfield(@args);
}

# HSCAN
sub hscan {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hscan(@args);
}

# HSET
sub hset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hset(@args);
}

# HSETEX
sub hsetex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hsetex(@args);
}

# HSETNX
sub hsetnx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hsetnx(@args);
}

# HSTRLEN
sub hstrlen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hstrlen(@args);
}

# HTTL
sub httl {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->httl(@args);
}

# HVALS
sub hvals {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->hvals(@args);
}

# INCR
sub incr {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->incr(@args);
}

# INCRBY
sub incrby {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->incrby(@args);
}

# INCRBYFLOAT
sub incrbyfloat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->incrbyfloat(@args);
}

# INCREX
sub increx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->increx(@args);
}

# INFO
sub info {
    my ($self, @args) = @_;
    return $self->{redis}->info(@args);
}

# KEYS
sub keys {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (defined $args[0]) {
        $args[0] = "$self->{namespace_escaped}:$args[0]";
    }

    my $after = sub {
        my @result = @_;
        @result = $self->rem_namespace(@result);
        return @result;
    };
    if ($cb) {
        return $self->{redis}->keys(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->keys(@args)) if wantarray;
    my $result = $self->{redis}->keys(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# LASTSAVE
sub lastsave {
    my ($self, @args) = @_;
    return $self->{redis}->lastsave(@args);
}

# LATENCY
sub latency {
    my ($self, @args) = @_;
    return $self->{redis}->latency(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'doctor' ||
        $subcommand eq 'graph' ||
        $subcommand eq 'help' ||
        $subcommand eq 'histogram' ||
        $subcommand eq 'history' ||
        $subcommand eq 'latest' ||
        $subcommand eq 'reset'
    ) {
        return $self->{redis}->latency(@args);
    }

    croak "unknown command 'latency $args[0]'" if $self->{strict};
    carp "unknown command 'latency $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->latency(@args);
}

# LATENCY DOCTOR
sub latency_doctor {
    my ($self, @args) = @_;
    return $self->{redis}->latency_doctor(@args);
}

# LATENCY GRAPH
sub latency_graph {
    my ($self, @args) = @_;
    return $self->{redis}->latency_graph(@args);
}

# LATENCY HELP
sub latency_help {
    my ($self, @args) = @_;
    return $self->{redis}->latency_help(@args);
}

# LATENCY HISTOGRAM
sub latency_histogram {
    my ($self, @args) = @_;
    return $self->{redis}->latency_histogram(@args);
}

# LATENCY HISTORY
sub latency_history {
    my ($self, @args) = @_;
    return $self->{redis}->latency_history(@args);
}

# LATENCY LATEST
sub latency_latest {
    my ($self, @args) = @_;
    return $self->{redis}->latency_latest(@args);
}

# LATENCY RESET
sub latency_reset {
    my ($self, @args) = @_;
    return $self->{redis}->latency_reset(@args);
}

# LCS
sub lcs {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i <= 1 && $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lcs(@args);
}

# LINDEX
sub lindex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lindex(@args);
}

# LINSERT
sub linsert {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->linsert(@args);
}

# LLEN
sub llen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->llen(@args);
}

# LMOVE
sub lmove {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lmove(@args);
}

# LMOVEM
sub lmovem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lmovem(@args);
}

# LMPOP
sub lmpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->lmpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->lmpop(@args)) if wantarray;
    my $result = $self->{redis}->lmpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# LOLWUT
sub lolwut {
    my ($self, @args) = @_;
    return $self->{redis}->lolwut(@args);
}

# LPOP
sub lpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lpop(@args);
}

# LPOS
sub lpos {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lpos(@args);
}

# LPUSH
sub lpush {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lpush(@args);
}

# LPUSHX
sub lpushx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lpushx(@args);
}

# LRANGE
sub lrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lrange(@args);
}

# LREM
sub lrem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lrem(@args);
}

# LSET
sub lset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->lset(@args);
}

# LTRIM
sub ltrim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->ltrim(@args);
}

# MEMORY
sub memory {
    my ($self, @args) = @_;
    return $self->{redis}->memory(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'doctor' ||
        $subcommand eq 'help' ||
        $subcommand eq 'malloc-stats' ||
        $subcommand eq 'purge' ||
        $subcommand eq 'stats'
    ) {
        return $self->{redis}->memory(@args);
    }

    # MEMORY USAGE
    if ($subcommand eq 'usage') {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->memory($name, @args);
    }

    croak "unknown command 'memory $args[0]'" if $self->{strict};
    carp "unknown command 'memory $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->memory(@args);
}

# MEMORY DOCTOR
sub memory_doctor {
    my ($self, @args) = @_;
    return $self->{redis}->memory_doctor(@args);
}

# MEMORY HELP
sub memory_help {
    my ($self, @args) = @_;
    return $self->{redis}->memory_help(@args);
}

# MEMORY PURGE
sub memory_purge {
    my ($self, @args) = @_;
    return $self->{redis}->memory_purge(@args);
}

# MEMORY STATS
sub memory_stats {
    my ($self, @args) = @_;
    return $self->{redis}->memory_stats(@args);
}

# MEMORY USAGE
sub memory_usage {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->memory_usage(@args);
}

# MGET
sub mget {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->mget(@args);
}

# MIGRATE
sub migrate {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 2) {
        # add_namespace keeps the empty string for the KEYS option as is.
        ($args[2]) = $self->add_namespace($args[2]);
    }
    for (my $i = 5; $i < @args; $i++) {
        my $option = lc($args[$i] // '');
        if ($option eq 'auth') {
            $i += 1;
        } elsif ($option eq 'auth2') {
            $i += 2;
        } elsif ($option eq 'keys') {
            @args[$i + 1 .. $#args] = $self->add_namespace(@args[$i + 1 .. $#args]);
            last;
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->migrate(@args);
}

# MODULE
sub module {
    my ($self, @args) = @_;
    return $self->{redis}->module(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'help' ||
        $subcommand eq 'list' ||
        $subcommand eq 'load' ||
        $subcommand eq 'loadex' ||
        $subcommand eq 'unload'
    ) {
        return $self->{redis}->module(@args);
    }

    croak "unknown command 'module $args[0]'" if $self->{strict};
    carp "unknown command 'module $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->module(@args);
}

# MODULE HELP
sub module_help {
    my ($self, @args) = @_;
    return $self->{redis}->module_help(@args);
}

# MODULE LIST
sub module_list {
    my ($self, @args) = @_;
    return $self->{redis}->module_list(@args);
}

# MODULE LOAD
sub module_load {
    my ($self, @args) = @_;
    return $self->{redis}->module_load(@args);
}

# MODULE LOADEX
sub module_loadex {
    my ($self, @args) = @_;
    return $self->{redis}->module_loadex(@args);
}

# MODULE UNLOAD
sub module_unload {
    my ($self, @args) = @_;
    return $self->{redis}->module_unload(@args);
}

# MONITOR
sub monitor {
    my ($self, @args) = @_;
    return $self->{redis}->monitor(@args);
}

# MOVE
sub move {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->move(@args);
}

# MSET
sub mset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i += 2) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->mset(@args);
}

# MSETEX
sub msetex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys * 2 && $i < @args; $i += 2) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->msetex(@args);
}

# MSETNX
sub msetnx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i += 2) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->msetnx(@args);
}

# MULTI
sub multi {
    my ($self, @args) = @_;
    return $self->{redis}->multi(@args);
}

# OBJECT
sub object {
    my ($self, @args) = @_;
    return $self->{redis}->object(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'encoding' ||
        $subcommand eq 'freq' ||
        $subcommand eq 'idletime' ||
        $subcommand eq 'refcount'
    ) {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->object($name, @args);
    }

    # OBJECT HELP
    if ($subcommand eq 'help') {
        return $self->{redis}->object(@args);
    }

    croak "unknown command 'object $args[0]'" if $self->{strict};
    carp "unknown command 'object $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->object(@args);
}

# OBJECT ENCODING
sub object_encoding {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->object_encoding(@args);
}

# OBJECT FREQ
sub object_freq {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->object_freq(@args);
}

# OBJECT HELP
sub object_help {
    my ($self, @args) = @_;
    return $self->{redis}->object_help(@args);
}

# OBJECT IDLETIME
sub object_idletime {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->object_idletime(@args);
}

# OBJECT REFCOUNT
sub object_refcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->object_refcount(@args);
}

# PERSIST
sub persist {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->persist(@args);
}

# PEXPIRE
sub pexpire {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pexpire(@args);
}

# PEXPIREAT
sub pexpireat {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pexpireat(@args);
}

# PEXPIRETIME
sub pexpiretime {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pexpiretime(@args);
}

# PFADD
sub pfadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pfadd(@args);
}

# PFCOUNT
sub pfcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pfcount(@args);
}

# PFDEBUG
sub pfdebug {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 1) {
        ($args[1]) = $self->add_namespace($args[1]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pfdebug(@args);
}

# PFMERGE
sub pfmerge {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    for (my $i = 1; $i < @args; $i++) {
        push @positions, $i;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pfmerge(@args);
}

# PFSELFTEST
sub pfselftest {
    my ($self, @args) = @_;
    return $self->{redis}->pfselftest(@args);
}

# PING
sub ping {
    my ($self, @args) = @_;
    return $self->{redis}->ping(@args);
}

# PSETEX
sub psetex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->psetex(@args);
}

# PSYNC
sub psync {
    my ($self, @args) = @_;
    return $self->{redis}->psync(@args);
}

# PTTL
sub pttl {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->pttl(@args);
}

# PUBLISH
sub publish {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->publish(@args);
}

# PUBSUB
sub pubsub {
    my ($self, @args) = @_;
    return $self->{redis}->pubsub(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # PUBSUB HELP, PUBSUB NUMPAT
    if (
        $subcommand eq 'help' ||
        $subcommand eq 'numpat'
    ) {
        return $self->{redis}->pubsub(@args);
    }

    croak "unknown command 'pubsub $args[0]'" if $self->{strict};
    carp "unknown command 'pubsub $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->pubsub(@args);
}

# PUBSUB HELP
sub pubsub_help {
    my ($self, @args) = @_;
    return $self->{redis}->pubsub_help(@args);
}

# PUBSUB NUMPAT
sub pubsub_numpat {
    my ($self, @args) = @_;
    return $self->{redis}->pubsub_numpat(@args);
}

# QUIT
sub quit {
    my ($self, @args) = @_;
    return $self->{redis}->quit(@args);
}

# RANDOMKEY
sub randomkey {
    my ($self, @args) = @_;
    return $self->{redis}->randomkey(@args);
}

# READONLY
sub readonly {
    my ($self, @args) = @_;
    croak "unsafe command 'readonly'" if $self->{strict};
    return $self->{redis}->readonly(@args);
}

# READWRITE
sub readwrite {
    my ($self, @args) = @_;
    croak "unsafe command 'readwrite'" if $self->{strict};
    return $self->{redis}->readwrite(@args);
}

# RENAME
sub rename {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->rename(@args);
}

# RENAMENX
sub renamenx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->renamenx(@args);
}

# REPLCONF
sub replconf {
    my ($self, @args) = @_;
    croak "unsafe command 'replconf'" if $self->{strict};
    return $self->{redis}->replconf(@args);
}

# REPLICAOF
sub replicaof {
    my ($self, @args) = @_;
    croak "unsafe command 'replicaof'" if $self->{strict};
    return $self->{redis}->replicaof(@args);
}

# RESET
sub reset {
    my ($self, @args) = @_;
    return $self->{redis}->reset(@args);
}

# RESTORE
sub restore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->restore(@args);
}

# ROLE
sub role {
    my ($self, @args) = @_;
    return $self->{redis}->role(@args);
}

# RPOP
sub rpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->rpop(@args);
}

# RPOPLPUSH
sub rpoplpush {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->rpoplpush(@args);
}

# RPUSH
sub rpush {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->rpush(@args);
}

# RPUSHX
sub rpushx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->rpushx(@args);
}

# SADD
sub sadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sadd(@args);
}

# SAVE
sub save {
    my ($self, @args) = @_;
    return $self->{redis}->save(@args);
}

# SCAN
sub scan {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @res;

    # first arg is iteration key
    if (@args) {
        push @res, shift @args;
    }

    # parse options
    my $has_pattern = 0;
    while (@args) {
        my $option = lc shift @args;
        if ($option eq 'match') {
            my $pattern = shift @args;
            push @res, $option, "$self->{namespace_escaped}:$pattern";
            $has_pattern = 1;
        } elsif ($option eq 'count' || $option eq 'type') {
            push @res, $option, shift @args;
        } else {
            push @res, $option;
        }
    }

    # add pattern option
    unless ($has_pattern) {
        push @res, 'match', "$self->{namespace_escaped}:*";
    }
    @args = @res;

    my $after = sub {
        my @result = @_;
        if (@result) {
            @result = ($result[0], [ $self->rem_namespace(@{ $result[1] || [] }) ]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->scan(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->scan(@args)) if wantarray;
    my $result = $self->{redis}->scan(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# SCARD
sub scard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->scard(@args);
}

# SCRIPT
sub script {
    my ($self, @args) = @_;
    return $self->{redis}->script(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'debug' ||
        $subcommand eq 'exists' ||
        $subcommand eq 'flush' ||
        $subcommand eq 'help' ||
        $subcommand eq 'kill' ||
        $subcommand eq 'load' ||
        $subcommand eq 'show'
    ) {
        return $self->{redis}->script(@args);
    }

    croak "unknown command 'script $args[0]'" if $self->{strict};
    carp "unknown command 'script $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->script(@args);
}

# SCRIPT DEBUG
sub script_debug {
    my ($self, @args) = @_;
    return $self->{redis}->script_debug(@args);
}

# SCRIPT EXISTS
sub script_exists {
    my ($self, @args) = @_;
    return $self->{redis}->script_exists(@args);
}

# SCRIPT FLUSH
sub script_flush {
    my ($self, @args) = @_;
    return $self->{redis}->script_flush(@args);
}

# SCRIPT HELP
sub script_help {
    my ($self, @args) = @_;
    return $self->{redis}->script_help(@args);
}

# SCRIPT KILL
sub script_kill {
    my ($self, @args) = @_;
    return $self->{redis}->script_kill(@args);
}

# SCRIPT LOAD
sub script_load {
    my ($self, @args) = @_;
    return $self->{redis}->script_load(@args);
}

# SCRIPT SHOW
sub script_show {
    my ($self, @args) = @_;
    return $self->{redis}->script_show(@args);
}

# SDIFF
sub sdiff {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sdiff(@args);
}

# SDIFFCARD
sub sdiffcard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->sdiffcard(@args);
}

# SDIFFSTORE
sub sdiffstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    for (my $i = 1; $i < @args; $i++) {
        push @positions, $i;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sdiffstore(@args);
}

# SELECT
sub select {
    my ($self, @args) = @_;
    return $self->{redis}->select(@args);
}

# SET
sub set {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->set(@args);
}

# SETBIT
sub setbit {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->setbit(@args);
}

# SETEX
sub setex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->setex(@args);
}

# SETNX
sub setnx {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->setnx(@args);
}

# SETRANGE
sub setrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->setrange(@args);
}

# SHUTDOWN
sub shutdown {
    my ($self, @args) = @_;
    croak "unsafe command 'shutdown'" if $self->{strict};
    return $self->{redis}->shutdown(@args);
}

# SINTER
sub sinter {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sinter(@args);
}

# SINTERCARD
sub sintercard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->sintercard(@args);
}

# SINTERSTORE
sub sinterstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    for (my $i = 1; $i < @args; $i++) {
        push @positions, $i;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sinterstore(@args);
}

# SISMEMBER
sub sismember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sismember(@args);
}

# SLAVEOF
sub slaveof {
    my ($self, @args) = @_;
    croak "unsafe command 'slaveof'" if $self->{strict};
    return $self->{redis}->slaveof(@args);
}

# SLOWLOG
sub slowlog {
    my ($self, @args) = @_;
    return $self->{redis}->slowlog(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'get' ||
        $subcommand eq 'help' ||
        $subcommand eq 'len' ||
        $subcommand eq 'reset'
    ) {
        return $self->{redis}->slowlog(@args);
    }

    croak "unknown command 'slowlog $args[0]'" if $self->{strict};
    carp "unknown command 'slowlog $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->slowlog(@args);
}

# SLOWLOG GET
sub slowlog_get {
    my ($self, @args) = @_;
    return $self->{redis}->slowlog_get(@args);
}

# SLOWLOG HELP
sub slowlog_help {
    my ($self, @args) = @_;
    return $self->{redis}->slowlog_help(@args);
}

# SLOWLOG LEN
sub slowlog_len {
    my ($self, @args) = @_;
    return $self->{redis}->slowlog_len(@args);
}

# SLOWLOG RESET
sub slowlog_reset {
    my ($self, @args) = @_;
    return $self->{redis}->slowlog_reset(@args);
}

# SMEMBERS
sub smembers {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->smembers(@args);
}

# SMISMEMBER
sub smismember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->smismember(@args);
}

# SMOVE
sub smove {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->smove(@args);
}

# SORT
sub sort {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @res;
    if (@args) {
        push @res, $self->add_namespace(shift @args);
    }
    while (@args) {
        my $option = lc shift @args;
        if ($option eq 'limit') {
            my $start = shift @args;
            my $count = shift @args;
            push @res, $option, $start, $count;
        } elsif ($option eq 'by' || $option eq 'store') {
            my $key = shift @args;
            push @res, $option, $self->add_namespace($key);
        } elsif ($option eq 'get') {
            my $key = shift @args;
            ($key) = $self->add_namespace($key) unless $key eq '#';
            push @res, $option, $key;
        } else {
            push @res, $option;
        }
    }
    @args = @res;

    push @args, $cb if $cb;
    return $self->{redis}->sort(@args);
}

# SPOP
sub spop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->spop(@args);
}

# SPUBLISH
sub spublish {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->spublish(@args);
}

# SRANDMEMBER
sub srandmember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->srandmember(@args);
}

# SREM
sub srem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->srem(@args);
}

# SSCAN
sub sscan {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sscan(@args);
}

# SSUBSCRIBE
sub ssubscribe {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    @args = $self->add_namespace(@args);

    push @args, $cb if $cb;
    return $self->{redis}->ssubscribe(@args);
}

# STRLEN
sub strlen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->strlen(@args);
}

# SUBSTR
sub substr {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->substr(@args);
}

# SUNION
sub sunion {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sunion(@args);
}

# SUNIONCARD
sub sunioncard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->sunioncard(@args);
}

# SUNIONSTORE
sub sunionstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    for (my $i = 1; $i < @args; $i++) {
        push @positions, $i;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->sunionstore(@args);
}

# SUNSUBSCRIBE
sub sunsubscribe {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    @args = $self->add_namespace(@args);

    push @args, $cb if $cb;
    return $self->{redis}->sunsubscribe(@args);
}

# SWAPDB
sub swapdb {
    my ($self, @args) = @_;
    return $self->{redis}->swapdb(@args);
}

# SYNC
sub sync {
    my ($self, @args) = @_;
    return $self->{redis}->sync(@args);
}

# TIME
sub time {
    my ($self, @args) = @_;
    return $self->{redis}->time(@args);
}

# TOUCH
sub touch {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->touch(@args);
}

# TRIMSLOTS
sub trimslots {
    my ($self, @args) = @_;
    croak "unsafe command 'trimslots'" if $self->{strict};
    return $self->{redis}->trimslots(@args);
}

# TTL
sub ttl {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->ttl(@args);
}

# TYPE
sub type {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->type(@args);
}

# UNLINK
sub unlink {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->unlink(@args);
}

# UNWATCH
sub unwatch {
    my ($self, @args) = @_;
    return $self->{redis}->unwatch(@args);
}

# VADD
sub vadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vadd(@args);
}

# VCARD
sub vcard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vcard(@args);
}

# VDIM
sub vdim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vdim(@args);
}

# VEMB
sub vemb {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vemb(@args);
}

# VGETATTR
sub vgetattr {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vgetattr(@args);
}

# VINFO
sub vinfo {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vinfo(@args);
}

# VISMEMBER
sub vismember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vismember(@args);
}

# VLINKS
sub vlinks {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vlinks(@args);
}

# VRANDMEMBER
sub vrandmember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vrandmember(@args);
}

# VRANGE
sub vrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vrange(@args);
}

# VREM
sub vrem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vrem(@args);
}

# VSETATTR
sub vsetattr {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vsetattr(@args);
}

# VSIM
sub vsim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->vsim(@args);
}

# WAIT
sub wait {
    my ($self, @args) = @_;
    return $self->{redis}->wait(@args);
}

# WAITAOF
sub waitaof {
    my ($self, @args) = @_;
    return $self->{redis}->waitaof(@args);
}

# WATCH
sub watch {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    for (my $i = 0; $i < @args; $i++) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->watch(@args);
}

# XACK
sub xack {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xack(@args);
}

# XACKDEL
sub xackdel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xackdel(@args);
}

# XADD
sub xadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xadd(@args);
}

# XAUTOCLAIM
sub xautoclaim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xautoclaim(@args);
}

# XCFGSET
sub xcfgset {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xcfgset(@args);
}

# XCLAIM
sub xclaim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xclaim(@args);
}

# XDEL
sub xdel {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xdel(@args);
}

# XDELEX
sub xdelex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xdelex(@args);
}

# XGROUP
sub xgroup {
    my ($self, @args) = @_;
    return $self->{redis}->xgroup(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    if (
        $subcommand eq 'create' ||
        $subcommand eq 'createconsumer' ||
        $subcommand eq 'delconsumer' ||
        $subcommand eq 'destroy' ||
        $subcommand eq 'setid'
    ) {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->xgroup($name, @args);
    }

    # XGROUP HELP
    if ($subcommand eq 'help') {
        return $self->{redis}->xgroup(@args);
    }

    croak "unknown command 'xgroup $args[0]'" if $self->{strict};
    carp "unknown command 'xgroup $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->xgroup(@args);
}

# XGROUP CREATE
sub xgroup_create {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xgroup_create(@args);
}

# XGROUP CREATECONSUMER
sub xgroup_createconsumer {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xgroup_createconsumer(@args);
}

# XGROUP DELCONSUMER
sub xgroup_delconsumer {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xgroup_delconsumer(@args);
}

# XGROUP DESTROY
sub xgroup_destroy {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xgroup_destroy(@args);
}

# XGROUP HELP
sub xgroup_help {
    my ($self, @args) = @_;
    return $self->{redis}->xgroup_help(@args);
}

# XGROUP SETID
sub xgroup_setid {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xgroup_setid(@args);
}

# XIDMPRECORD
sub xidmprecord {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xidmprecord(@args);
}

# XINFO
sub xinfo {
    my ($self, @args) = @_;
    return $self->{redis}->xinfo(@args) if !@args || ref $args[0];

    my $subcommand = lc $args[0];

    # XINFO CONSUMERS, XINFO GROUPS, XINFO STREAM
    if (
        $subcommand eq 'consumers' ||
        $subcommand eq 'groups' ||
        $subcommand eq 'stream'
    ) {
        my $name = shift @args;
        my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

        if (@args > 0) {
            ($args[0]) = $self->add_namespace($args[0]);
        }

        push @args, $cb if $cb;
        return $self->{redis}->xinfo($name, @args);
    }

    # XINFO HELP
    if ($subcommand eq 'help') {
        return $self->{redis}->xinfo(@args);
    }

    croak "unknown command 'xinfo $args[0]'" if $self->{strict};
    carp "unknown command 'xinfo $args[0]'. passing arguments to the redis server as is.";
    return $self->{redis}->xinfo(@args);
}

# XINFO CONSUMERS
sub xinfo_consumers {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xinfo_consumers(@args);
}

# XINFO GROUPS
sub xinfo_groups {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xinfo_groups(@args);
}

# XINFO HELP
sub xinfo_help {
    my ($self, @args) = @_;
    return $self->{redis}->xinfo_help(@args);
}

# XINFO STREAM
sub xinfo_stream {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xinfo_stream(@args);
}

# XLEN
sub xlen {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xlen(@args);
}

# XNACK
sub xnack {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xnack(@args);
}

# XPENDING
sub xpending {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xpending(@args);
}

# XRANGE
sub xrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xrange(@args);
}

# XREAD
sub xread {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $first;
    for (my $i = 0; $i < @args; $i++) {
        if (lc($args[$i] // '') eq 'streams') {
            $first = $i + 1;
            last;
        }
    }
    if (defined $first) {
        for (my $i = $first; $i <= $first + int((@args - $first) / 2) - 1 && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        @result = map {
            ref $_ eq 'ARRAY' ? [ $self->rem_namespace($_->[0]), @{$_}[1 .. $#$_] ] : $_
        } @result;
        return @result;
    };
    if ($cb) {
        return $self->{redis}->xread(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->xread(@args)) if wantarray;
    my $result = $self->{redis}->xread(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# XREADGROUP
sub xreadgroup {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $first;
    for (my $i = 3; $i < @args; $i++) {
        if (lc($args[$i] // '') eq 'streams') {
            $first = $i + 1;
            last;
        }
    }
    if (defined $first) {
        for (my $i = $first; $i <= $first + int((@args - $first) / 2) - 1 && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        @result = map {
            ref $_ eq 'ARRAY' ? [ $self->rem_namespace($_->[0]), @{$_}[1 .. $#$_] ] : $_
        } @result;
        return @result;
    };
    if ($cb) {
        return $self->{redis}->xreadgroup(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->xreadgroup(@args)) if wantarray;
    my $result = $self->{redis}->xreadgroup(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# XREVRANGE
sub xrevrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xrevrange(@args);
}

# XSETID
sub xsetid {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xsetid(@args);
}

# XTRIM
sub xtrim {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->xtrim(@args);
}

# ZADD
sub zadd {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zadd(@args);
}

# ZCARD
sub zcard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zcard(@args);
}

# ZCOUNT
sub zcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zcount(@args);
}

# ZDIFF
sub zdiff {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->zdiff(@args);
}

# ZDIFFSTORE
sub zdiffstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    {
        my $numkeys = $args[1];
        if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
            for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
                push @positions, $i;
            }
        }
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zdiffstore(@args);
}

# ZINCRBY
sub zincrby {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zincrby(@args);
}

# ZINTER
sub zinter {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->zinter(@args);
}

# ZINTERCARD
sub zintercard {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->zintercard(@args);
}

# ZINTERSTORE
sub zinterstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    {
        my $numkeys = $args[1];
        if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
            for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
                push @positions, $i;
            }
        }
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zinterstore(@args);
}

# ZLEXCOUNT
sub zlexcount {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zlexcount(@args);
}

# ZMPOP
sub zmpop {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    my $after = sub {
        my @result = @_;
        if (@result) {
            ($result[0]) = $self->rem_namespace($result[0]);
        }
        return @result;
    };
    if ($cb) {
        return $self->{redis}->zmpop(@args, sub {
            my ($result, $error) = @_;
            $result = [ $after->(@$result) ] if ref $result eq 'ARRAY';
            $cb->($result, $error);
        });
    }
    return $after->($self->{redis}->zmpop(@args)) if wantarray;
    my $result = $self->{redis}->zmpop(@args);
    return ref $result eq 'ARRAY' ? [ $after->(@$result) ] : $result;
}

# ZMSCORE
sub zmscore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zmscore(@args);
}

# ZPOPMAX
sub zpopmax {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zpopmax(@args);
}

# ZPOPMIN
sub zpopmin {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zpopmin(@args);
}

# ZRANDMEMBER
sub zrandmember {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrandmember(@args);
}

# ZRANGE
sub zrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrange(@args);
}

# ZRANGEBYLEX
sub zrangebylex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrangebylex(@args);
}

# ZRANGEBYSCORE
sub zrangebyscore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrangebyscore(@args);
}

# ZRANGESTORE
sub zrangestore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    if (@args > 1) {
        push @positions, 1;
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrangestore(@args);
}

# ZRANK
sub zrank {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrank(@args);
}

# ZREM
sub zrem {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrem(@args);
}

# ZREMRANGEBYLEX
sub zremrangebylex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zremrangebylex(@args);
}

# ZREMRANGEBYRANK
sub zremrangebyrank {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zremrangebyrank(@args);
}

# ZREMRANGEBYSCORE
sub zremrangebyscore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zremrangebyscore(@args);
}

# ZREVRANGE
sub zrevrange {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrevrange(@args);
}

# ZREVRANGEBYLEX
sub zrevrangebylex {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrevrangebylex(@args);
}

# ZREVRANGEBYSCORE
sub zrevrangebyscore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrevrangebyscore(@args);
}

# ZREVRANK
sub zrevrank {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zrevrank(@args);
}

# ZSCAN
sub zscan {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zscan(@args);
}

# ZSCORE
sub zscore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    if (@args > 0) {
        ($args[0]) = $self->add_namespace($args[0]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zscore(@args);
}

# ZUNION
sub zunion {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my $numkeys = $args[0];
    if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
        for (my $i = 1; $i < 1 + $numkeys && $i < @args; $i++) {
            ($args[$i]) = $self->add_namespace($args[$i]);
        }
    }

    push @args, $cb if $cb;
    return $self->{redis}->zunion(@args);
}

# ZUNIONSTORE
sub zunionstore {
    my ($self, @args) = @_;
    my $cb = @args && ref $args[-1] eq 'CODE' ? pop @args : undef;

    my @positions;
    if (@args > 0) {
        push @positions, 0;
    }
    {
        my $numkeys = $args[1];
        if (defined $numkeys && $numkeys =~ /\A[0-9]+\z/) {
            for (my $i = 2; $i < 2 + $numkeys && $i < @args; $i++) {
                push @positions, $i;
            }
        }
    }
    my %seen;
    for my $i (grep { !$seen{$_}++ } @positions) {
        ($args[$i]) = $self->add_namespace($args[$i]);
    }

    push @args, $cb if $cb;
    return $self->{redis}->zunionstore(@args);
}

## use critic
# END GENERATED COMMANDS

1;
__END__

=encoding utf-8

=head1 NAME

Redis::Namespace - a wrapper of Redis.pm that namespaces all Redis calls


=head1 SYNOPSIS

  use Redis;
  use Redis::Namespace;
  
  my $redis = Redis->new;
  my $ns = Redis::Namespace->new(redis => $redis, namespace => 'fugu');
  
  $ns->set('foo', 'bar');
  # will call $redis->set('fugu:foo', 'bar');
  
  my $foo = $ns->get('foo');
  # will call $redis->get('fugu:foo');


=head1 DESCRIPTION

Redis::Namespace is a wrapper of Redis.pm that namespaces all Redis calls.
It is useful when you have multiple systems using Redis differently in your app.

=head1 OPTIONS

=over 4

=item redis

An instance of L<Redis.pm|https://github.com/melo/perl-redis> or L<Redis::Fast|https://github.com/shogo82148/Redis-Fast>.

=item namespace

prefix of keys.

=item guess

If C<Redis::Namespace> doesn't known the command,
call L<command info|https://redis.io/docs/latest/commands/command-info/> and guess positions of keys.
It is boolean value.
The default value is false.

=item strict

It is boolean value.
If it is true, C<Redis::Namespace> doesn't execute unsafe commands
which may break another namepace and/or change the state of redis-server, such as C<FLUSHALL> and C<SHUTDOWN>.
Also, unknown commands are not executed, because there is no guarantee that the command does not break another namepace.
The default value is false.

=back

=head1 METHODS

=head2 scan_callback

    $ns->scan_callback( sub { my $key = shift; ... } );

    $ns->scan_callback( match => 'foo:*', sub { my $key = shift; ... } );

Execute a callback exactly once for every matching key within the namespace.

The key is passed as one and only argument to the callback.

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>


=head1 SEE ALSO

=over 4

=item *

L<Redis|http://redis.io/>

=item *

L<Redis.pm|https://github.com/melo/perl-redis>

=item *

L<redis-namespace|https://github.com/resque/redis-namespace>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
