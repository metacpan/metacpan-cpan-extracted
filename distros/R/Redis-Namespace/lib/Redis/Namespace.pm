package Redis::Namespace;

use strict;
use warnings;
our $VERSION = '0.10';

use Redis;
use Carp qw(carp croak);

our %BEFORE_FILTERS = (
    # do nothing
    none => sub {
        my ($self, @args) = @_;
        return @args;
    },

    # GET key => GET namespace:key
    first => sub {
        my ($self, @args) = @_;
        if(@args) {
            my $first = shift @args;
            return ($self->add_namespace($first), @args);
        } else {
            return @args;
        }
    },

    # MGET key1 key2 => MGET namespace:key1 namespace:key2
    all => sub {
        my ($self, @args) = @_;
        return $self->add_namespace(@args);
    },

    exclude_first => sub {
        my ($self, @args) = @_;
        if(@args) {
            my $first = shift @args;
            return (
                $first,
                $self->add_namespace(@args),
            );
        } else {
            return @args;
        }
    },

    # BLPOP key1 key2 timeout => BLPOP namespace:key1 namespace:key2 timeout
    exclude_last => sub {
        my ($self, @args) = @_;
        if(@args) {
            my $last = pop @args;
            return (
                $self->add_namespace(@args),
                $last
            );
        } else {
            return @args;
        }
    },

    # MSET key1 value1 key2 value2 => MSET namespace:key1 value1 namespace:key2 value2
    alternate => sub {
        my ($self, @args) = @_;
        my @result;
        for my $i(0..@args-1) {
            if($i % 2 == 0) {
                push @result, $self->add_namespace($args[$i]);
            } else {
                push @result, $args[$i];
            }
        }
        return @result;
    },

    keys => sub {
        my ($self, $pattern) = @_;
        return unless defined $pattern;
        my $namespace = $self->{namespace_escaped};
        return "$namespace:$pattern";
    },

    sort => sub {
        my ($self, @args) = @_;
        my @res;
        if(@args) {
            my $first = shift @args;
            push @res, $self->add_namespace($first);
        }
        while(@args) {
            my $option = lc shift @args;
            if($option eq 'limit') {
                my $start = shift @args;
                my $count = shift @args;
                push @res, $option, $start, $count;
            } elsif($option eq 'by' || $option eq 'store') {
                my $key = shift @args;
                push @res, $option, $self->add_namespace($key);
            } elsif($option eq 'get') {
                my $key = shift @args;
                ($key) = $self->add_namespace($key) unless $key eq '#';
                push @res, $option, $key;
            } else {
                push @res, $option;
            }
        }
        return @res;
    },

    # EVAL script 2 key1 key2 arg1 arg2 => EVAL script 2 ns:key1 ns:key2 arg1 arg2
    eval_style => sub {
        my ($self, $script, $number, @args) = @_;
        my @keys = $self->add_namespace(splice @args, 0, $number);
        return ($script, $number, @keys, @args);
    },

    # ZINTERSTORE key0 2 key1 key2 SOME_OPTIONS => ZINTERSTORE ns:key0 2 ns:key1 ns:key2
    exclude_options => sub {
        my ($self, $first, $number, @args) = @_;
        my @keys = $self->add_namespace(splice @args, 0, $number);
        return ($self->add_namespace($first), $number, @keys, @args);
    },


    scan => sub {
        my ($self, @args) = @_;
        my @res;

        my $namespace = $self->{namespace_escaped};

        # first arg is iteration key
        if(@args) {
            my $first = shift @args;
            push @res, $first;
        }

        # parse options
        my $has_pattern = 0;
        while(@args) {
            my $option = lc shift @args;
            if($option eq 'match') {
                my $pattern = shift @args;
                push @res, $option, "$namespace:$pattern";
                $has_pattern = 1;
            } elsif($option eq 'count') {
                my $count = shift @args;
                push @res, $option, $count;
            } else {
                push @res, $option;
            }
        }

        # add pattern option
        unless($has_pattern) {
            push @res, 'match', "$namespace:*";
        }

        return @res;
    },

    # MIGRATE host port key destination-db timeout => MIGRATE host port namespace:key destination-db timeout
    # MIGRATE host port "" destination-db timeout KEYS => MIGRATE host port namespace:key destination-db timeout
    migrate => sub {
        my ($self, @args) = @_;
        my @res = splice @args, 0, 5;

        # key may be the empty string in Redis-3.2 and above
        if(scalar @res >= 3 && $res[2] ne '') {
            ($res[2]) = $self->add_namespace($res[2]);
        }

        while(@args) {
            my $option = lc shift @args;
            if($option eq 'keys') {
                push @res, $option, $self->add_namespace(@args);
                @args = ();
            } else {
                push @res, $option;
            }
        }
        return @res;
    },

    # GEORADIUS key longitude latitude radius m|km|ft|mi STORE key STOREDIST key => GEORADIUS namespace:key longitude latitude radius m|km|ft|mi STORE namespace:key STOREDIST namespace:key
    georadius => sub {
        my ($self, @args) = @_;
        my @res;

        # key
        if(@args) {
            my $first = shift @args;
            push @res, $self->add_namespace($first);
        }

        # longitude latitude radius m|km|ft|mi
        push @res, splice @args, 0, 4;

        while(@args) {
            my $option = lc shift @args;
            if($option eq 'store' || $option eq 'storedist') {
                my $key = shift @args;
                push @res, $option, $self->add_namespace($key);
            } elsif($option eq 'count') {
                my $count = shift @args;
                push @res, $option, $count;
            } else {
                push @res, $option;
            }
        }
        return @res;
    },

    # GEORADIUSBYMEMBER key member radius m|km|ft|mi STORE key STOREDIST key => GEORADIUSBYMEMBER namespace:key member radius m|km|ft|mi STORE namespace:key STOREDIST namespace:key
    georadiusbymember => sub {
        my ($self, @args) = @_;
        my @res;

        # key
        if(@args) {
            my $first = shift @args;
            push @res, $self->add_namespace($first);
        }

        # member radius m|km|ft|mi
        push @res, splice @args, 0, 3;

        while(@args) {
            my $option = lc shift @args;
            if($option eq 'store' || $option eq 'storedist') {
                my $key = shift @args;
                push @res, $option, $self->add_namespace($key);
            } elsif($option eq 'count') {
                my $count = shift @args;
                push @res, $option, $count;
            } else {
                push @res, $option;
            }
        }
        return @res;
    },

    # XREAD [COUNT count] [BLOCK milliseconds] STREAMS key [key ...] ID [ID ...]
    # => XREAD [COUNT count] [BLOCK milliseconds] STREAMS namespace:key [namespace:key ...] ID [ID ...]
    xread => sub {
        my ($self, @args) = @_;
        my @res;
        while(@args) {
            my $option = lc shift @args;
            if($option eq 'count' || $option eq 'block') {
                my $count = shift @args;
                push @res, $option, $count;
            } elsif ($option eq 'streams') {
                my $num = scalar(@args) / 2;
                push @res, $option, $self->add_namespace(@args[0..$num-1]), @args[$num..2*$num-1];
                @args = ();
            } else {
                push @res, $option;
            }
        }
        return @res;
    },

    # XREADGROUP GROUP group consumer [COUNT count] [BLOCK milliseconds] [NOACK] STREAMS key [key ...] ID [ID ...]
    # => XREADGROUP GROUP group consumer [COUNT count] [BLOCK milliseconds] [NOACK] STREAMS namespace:key [namespace:key ...] ID [ID ...]
    xreadgroup => sub {
        my ($self, @args) = @_;
        my @res;

        # GROUP group consumer
        push @res, splice @args, 0, 3;

        while(@args) {
            my $option = lc shift @args;
            if($option eq 'count' || $option eq 'block') {
                my $count = shift @args;
                push @res, $option, $count;
            } elsif ($option eq 'noack') {
                push @res, $option;
            } elsif ($option eq 'streams') {
                my $num = scalar(@args) / 2;
                push @res, $option, $self->add_namespace(@args[0..$num-1]), @args[$num..2*$num-1];
                @args = ();
            } else {
                push @res, $option;
            }
        }
        return @res;
    },
);

our %AFTER_FILTERS = (
    # do nothing
    none => sub {
        my ($self, @args) = @_;
        return @args;
    },

    # namespace:key1 namespace:key2 => key1 key2
    all => sub {
        my ($self, @args) = @_;
        return $self->rem_namespace(@args);
    },

    # namespace:key1 value => key1 value
    first => sub {
        my ($self, $first, @args) = @_;
        return ($self->rem_namespace($first), @args);
    },

    scan => sub {
        my ($self, $iter, $list) = @_;
        my @keys = map { $self->rem_namespace($_) } @$list;
        return ($iter, \@keys);
    },

    # [ [ namespace:key1, [...] ], [ namespace:key2, [...] ] => [ [ key1, [...] ], [ key2, [...] ]
    xread => sub {
        my ($self, @args) = @_;
        return map {
            if ($_) {
                my ($key, @rest) = @$_;
                [$self->rem_namespace($key), @rest];
            } else {
                $_;
            }
        } @args;
    },
);

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

# %UNSAFE_COMMANDS may break other namepace and/or change the state of redis-server.
# these commands are disable in strict mode.
our %UNSAFE_COMMANDS = (
    cluster   => 1,
    config    => 1,
    flushall  => 1,
    flushdb   => 1,
    readonly  => 1,
    readwrite => 1,
    replicaof => 1,
    slaveof   => 1,
    shutdown  => 1,
);

our %COMMANDS = (
    append           => [ 'first' ],
    auth             => [],
    bgrewriteaof     => [],
    bgsave           => [],
    bitcount         => [ 'first' ],
    bitfield         => [ 'first' ],
    bitpos           => [ 'first' ],
    bitop            => [ 'exclude_first' ],
    blpop            => [ 'exclude_last', 'first' ],
    brpop            => [ 'exclude_last', 'first' ],
    brpoplpush       => [ 'exclude_last' ],
    bzpopmax         => [ 'exclude_last', 'first' ],
    bzpopmin         => [ 'exclude_last', 'first' ],
    client           => [],
    cluster          => [],
    command          => [],
    config           => [],
    dbsize           => [],
    debug            => [ 'exclude_first' ],
    decr             => [ 'first' ],
    decrby           => [ 'first' ],
    del              => [ 'all' ],
    discard          => [],
    dump             => [ 'first' ],
    echo             => [],
    exists           => [ 'first' ],
    expire           => [ 'first' ],
    expireat         => [ 'first' ],
    eval             => [ 'eval_style' ],
    evalsha          => [ 'eval_style' ],
    exec             => [],
    flushall         => [],
    flushdb          => [],
    geoadd           => [ 'first' ],
    geodist          => [ 'first' ],
    geohash          => [ 'first' ],
    geopos           => [ 'first' ],
    georadius        => [ 'georadius' ],
    georadiusbymember=> [ 'georadiusbymember' ],
    get              => [ 'first' ],
    getbit           => [ 'first' ],
    getrange         => [ 'first' ],
    getset           => [ 'first' ],
    hscan            => [ 'first' ],
    hset             => [ 'first' ],
    hsetnx           => [ 'first' ],
    hstrlen          => [ 'first' ],
    hget             => [ 'first' ],
    hincrby          => [ 'first' ],
    hincrbyfloat     => [ 'first' ],
    hmget            => [ 'first' ],
    hmset            => [ 'first' ],
    hdel             => [ 'first' ],
    hexists          => [ 'first' ],
    hlen             => [ 'first' ],
    hkeys            => [ 'first' ],
    hvals            => [ 'first' ],
    hgetall          => [ 'first' ],
    incr             => [ 'first' ],
    incrby           => [ 'first' ],
    incrbyfloat      => [ 'first' ],
    info             => [],
    keys             => [ 'keys', 'all' ],
    lastsave         => [],
    lindex           => [ 'first' ],
    linsert          => [ 'first' ],
    llen             => [ 'first' ],
    lpop             => [ 'first' ],
    lpush            => [ 'first' ],
    lpushx           => [ 'first' ],
    lrange           => [ 'first' ],
    lrem             => [ 'first' ],
    lset             => [ 'first' ],
    ltrim            => [ 'first' ],
    memory           => [],
    mget             => [ 'all' ],
    migrate          => [ 'migrate' ],
    monitor          => [],
    move             => [ 'first' ],
    mscan            => [ 'first' ],
    mset             => [ 'alternate' ],
    msetnx           => [ 'alternate' ],
    object           => [ 'exclude_first' ],
    persist          => [ 'first' ],
    pexpire          => [ 'first' ],
    pexpireat        => [ 'first' ],
    pfadd            => [ 'first' ],
    pfcount          => [ 'all' ],
    pfmerge          => [ 'all' ],
    ping             => [],
    psetex           => [ 'first' ],
    psubscribe       => [ 'all' ],
    pttl             => [ 'first' ],
    publish          => [ 'first' ],
    punsubscribe     => [ 'all' ],
    quit             => [],
    randomkey        => [],
    readonly         => [],
    readwrite        => [],
    rename           => [ 'all' ],
    renamenx         => [ 'all' ],
    replicaof        => [],
    restore          => [ 'first' ],
    role             => [],
    rpop             => [ 'first' ],
    rpoplpush        => [ 'all' ],
    rpush            => [ 'first' ],
    rpushx           => [ 'first' ],
    sadd             => [ 'first' ],
    save             => [],
    scard            => [ 'first' ],
    script           => [],
    sdiff            => [ 'all' ],
    sdiffstore       => [ 'all' ],
    select           => [],
    set              => [ 'first' ],
    setbit           => [ 'first' ],
    setex            => [ 'first' ],
    setnx            => [ 'first' ],
    setrange         => [ 'first' ],
    shutdown         => [],
    sinter           => [ 'all' ],
    sinterstore      => [ 'all' ],
    sismember        => [ 'first' ],
    slaveof          => [],
    slowlog          => [],
    smembers         => [ 'first' ],
    smove            => [ 'exclude_last' ],
    scan             => [ 'scan', 'scan' ],
    sort             => [ 'sort'  ],
    spop             => [ 'first' ],
    srandmember      => [ 'first' ],
    srem             => [ 'first' ],
    sscan            => [ 'first' ],
    strlen           => [ 'first' ],
    subscribe        => [ 'all' ],
    sunion           => [ 'all' ],
    sunionstore      => [ 'all' ],
    swapdb           => [],
    sync             => [],
    time             => [],
    touch            => [ 'all' ],
    ttl              => [ 'first' ],
    type             => [ 'first' ],
    unsubscribe      => [ 'all' ],
    unlink           => [ 'all' ],
    unwatch          => [],
    wait             => [],
    watch            => [ 'all' ],
    xack             => [ 'first' ],
    xadd             => [ 'first' ],
    xclaim           => [ 'first' ],
    xdel             => [ 'first' ],
    xgroup => {
        create      => [ 'first' ],
        setid       => [ 'first' ],
        destroy     => [ 'first' ],
        delconsumer => [ 'first' ],
        help        => [],
    },
    xinfo => {
        consumers => [ 'first' ],
        groups    => [ 'first' ],
        stream    => [ 'first' ],
        help      => [],
    },
    xlen             => [ 'all' ],
    xpending         => [ 'first' ],
    xrange           => [ 'first' ],
    xread            => [ 'xread', 'xread' ],
    xreadgroup       => [ 'xreadgroup', 'xread' ],
    xrevrange        => [ 'first' ],
    xtrim            => [ 'first' ],
    zadd             => [ 'first' ],
    zcard            => [ 'first' ],
    zcount           => [ 'first' ],
    zincrby          => [ 'first' ],
    zinterstore      => [ 'exclude_options' ],
    zlexcount        => [ 'first' ],
    zpopmax          => [ 'first' ],
    zpopmin          => [ 'first' ],
    zrange           => [ 'first' ],
    zrangebylex      => [ 'first' ],
    zrangebyscore    => [ 'first' ],
    zrank            => [ 'first' ],
    zrem             => [ 'first' ],
    zremrangebylex   => [ 'first' ],
    zremrangebyrank  => [ 'first' ],
    zremrangebyscore => [ 'first' ],
    zrevrange        => [ 'first' ],
    zrevrangebylex   => [ 'first' ],
    zrevrangebyscore => [ 'first' ],
    zrevrank         => [ 'first' ],
    zscan            => [ 'first' ],
    zscore           => [ 'first' ],
    zunionstore      => [ 'exclude_options' ],

    multi              => [],
);

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

sub _wrap_method {
    my ($class, $command) = @_;
    my ($cmd, @extra) = split /_/, lc($command);
    my $filters = $COMMANDS{$cmd};
    my ($before, $after);
    my @subcommand = ();

    if ($filters) {
        if (ref $filters eq 'HASH') {
            # the target command has sub-commands
            if (@extra > 0) {
                my $subcommand = shift @extra;
                @subcommand = ($subcommand);
                $before = $BEFORE_FILTERS{$filters->{$subcommand}[0] // 'none'};
                $after = $AFTER_FILTERS{$filters->{$subcommand}[1] // 'none'};
            } else {
                $before = sub {
                    my ($self, $subcommand, @arg) = @_;
                    my $before = $BEFORE_FILTERS{$filters->{$subcommand}[0] // 'none'};
                    $after = $AFTER_FILTERS{$filters->{$subcommand}[1] // 'none'};
                    return ($subcommand, $before->($self, @arg));
                };
                $after = $AFTER_FILTERS{'none'};
            }
        } else {
            $before = $BEFORE_FILTERS{$filters->[0] // 'none'};
            $after = $AFTER_FILTERS{$filters->[1] // 'none'};
        }
    }

    return sub {
        my ($self, @args) = @_;
        my $redis = $self->{redis};
        my $wantarray = wantarray;
        my ($before, $after) = ($before, $after);

        if ($self->{strict} && $UNSAFE_COMMANDS{$command}) {
            croak "unsafe command '$command'";
        }

        if (!$before || !$after) {
            if ($self->{strict}) {
                croak "unknown command '$command'";
            }
            ($before, $after) = $self->_guess($command, @subcommand, @extra, @args);
        }

        if(@args && ref $args[-1] eq 'CODE') {
            my $cb = pop @args;
            @args = (@subcommand, $before->($self, @extra, @args));
            push @args, sub {
                my ($result, $error) = @_;
                $cb->($after->($self, $result), $error);
            };
        } else {
            @args = (@subcommand, $before->($self, @extra, @args));
        }

        if(!$wantarray) {
            $redis->$cmd(@args);
        } elsif($wantarray) {
            my @result = $redis->$cmd(@args);
            return $after->($self, @result);
        } else {
            my $result = $redis->$cmd(@args);
            return $after->($self, $result);
        }
    };
}

sub _guess {
    my ($self, $command, @args) = @_;
    if (!$self->{guess}) {
        carp "unknown command '$command'. passing arguments to the redis server as is.";
        return $BEFORE_FILTERS{none}, $AFTER_FILTERS{none};
    }

    if (my $cache = $self->{guess_cache}{$command}) {
        return @$cache;
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
        my ($before, $after) = ($BEFORE_FILTERS{none}, $AFTER_FILTERS{none});
        $self->{guess_cache}{$command} = [$before, $after];
        return $before, $after;
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
    my $after = $AFTER_FILTERS{none};
    $self->{guess_cache}{$command} = [$before, $after];
    return $before, $after;
}

sub _guess_movablekeys {
    my ($self, $command, @args) = @_;
    if(@args && ref $args[-1] eq 'CODE') {
        pop @args; # ignore callback function
    }

    my @keys = eval { $self->{redis}->command_getkeys($command, @args) }
        or return $BEFORE_FILTERS{none}, $AFTER_FILTERS{none};
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
        }, $AFTER_FILTERS{none}
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
        }, $AFTER_FILTERS{none}
    }

    croak "fail to guess key positions of command '$command'";
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
  my $command = $AUTOLOAD;
  $command =~ s/.*://;

  my $method = Redis::Namespace->_wrap_method($command);

  # Save this method for future calls
  no strict 'refs';
  *$AUTOLOAD = $method;

  goto $method;
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
    @args = $BEFORE_FILTERS{all}->($self, @args);
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
call L<command info|http://redis.io/commands/command-info> and guess positions of keys.
It is boolean value.

=item strict

It is boolean value.
If it is true, C<Redis::Namespace> doesn't execute unsafe commands
which may break another namepace and/or change the state of redis-server, such as C<FLUSHALL> and C<SHUTDOWN>.
Also, unknown commands are not executed, because there is no guarantee that the command does not break another namepace.

=back

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
