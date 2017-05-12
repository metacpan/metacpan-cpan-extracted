package Redis::Namespace;

use strict;
use warnings;
our $VERSION = '0.07';

use Redis;

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
                push @res, $option, $self->add_namespace($pattern);
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
            push @res, 'match', $self->add_namespace('*');
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
    }
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

our %COMMANDS = (
    append           => [ 'first' ],
    auth             => [],
    bgrewriteaof     => [],
    bgsave           => [],
    bitcount         => [ 'first' ],
    bitpos           => [ 'first' ],
    bitop            => [ 'exclude_first' ],
    blpop            => [ 'exclude_last', 'first' ],
    brpop            => [ 'exclude_last' ],
    brpoplpush       => [ 'exclude_last' ],
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
    georadius        => [ 'first' ],
    georadiusbymember=> [ 'first' ],
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
    keys             => [ 'first', 'all' ],
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
    mapped_hmset     => [ 'first' ],
    mapped_hmget     => [ 'first' ],
    mapped_mget      => [ 'all', 'all' ],
    mapped_mset      => [ 'all' ],
    mapped_msetnx    => [ 'all' ],
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
    sync             => [],
    time             => [],
    ttl              => [ 'first' ],
    type             => [ 'first' ],
    unsubscribe      => [ 'all' ],
    unwatch          => [],
    wait             => [],
    watch            => [ 'all' ],
    zadd             => [ 'first' ],
    zcard            => [ 'first' ],
    zcount           => [ 'first' ],
    zincrby          => [ 'first' ],
    zinterstore      => [ 'exclude_options' ],
    zlexcount        => [ 'first' ],
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

    wait_all_responses => [],
    wait_one_response  => [],
    multi              => [],
);

sub new {
    my $class = shift;
    my %args = @_;
    my $self  = bless {}, $class;

    $self->{redis} = $args{redis} || Redis->new(%args);
    $self->{namespace} = $args{namespace};
    $self->{warning} = $args{warning};
    $self->{subscribers} = {};
    if ($args{guess}) {
        my $version = $self->{redis}->info->{redis_version};
        my ($major, $minor, $rev) = split /\./, $version;
        if ( $major >= 3 || $major == 2 && $minor >= 8 && $rev >= 13 ) {
            $self->{guess} = 1;
        } elsif ($self->{warning}) {
            warn "guess option requires 2.8.13 or later. your redis version is $version";
        }
    }
    return $self;
}

sub _wrap_method {
    my ($class, $command) = @_;
    my $filters = $COMMANDS{$command};
    my $warn_message;
    my ($before, $after);

    if ($filters) {
        $before = $BEFORE_FILTERS{$filters->[0] // 'none'};
        $after = $AFTER_FILTERS{$filters->[1] // 'none'};
    }

    return sub {
        my ($self, @args) = @_;
        my $redis = $self->{redis};
        my $wantarray = wantarray;

        if (!$before || !$after) {
            if ($self->{guess}) {
                ($before, $after, $warn_message) = $self->_guess($command);
            } else {
                $warn_message = "Passing '$command' to redis as is.";
                $before = $BEFORE_FILTERS{none};
                $after = $AFTER_FILTERS{none};
            }
        }

        warn $warn_message if $warn_message && $self->{warning};

        if(@args && ref $args[-1] eq 'CODE') {
            my $cb = pop @args;
            @args = $before->($self, @args);
            push @args, sub {
                my ($result, $error) = @_;
                $cb->($after->($self, $result), $error);
            };
        } else {
            @args = $before->($self, @args);
        }

        if(!$wantarray) {
            $redis->$command(@args);
        } elsif($wantarray) {
            my @result = $redis->$command(@args);
            return $after->($self, @result);
        } else {
            my $result = $redis->$command(@args);
            return $after->($self, $result);
        }
    };
}

sub _guess {
    my ($self, $command) = @_;
    my $info = $self->{redis}->command('info', $command);
    my ($name, $num, $flags, $first, $last, $step) = @{$info->[0]};
    my ($movablekeys) = grep { $_ eq 'movablekeys' } @{$flags || []};

    unless ($name) {
        return $BEFORE_FILTERS{none}, $AFTER_FILTERS{none}, "Unknown command. Passing '$command' to redis as is.";
    }

    if ($movablekeys) {
        return $BEFORE_FILTERS{none}, $AFTER_FILTERS{none}, "movablekeys command. Passing '$command' to redis as is.";
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
    return $before, $AFTER_FILTERS{none};
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
    confess("Missing required callback in call to $command(), ")
        unless ref($cb) eq 'CODE';

    my $redis = $self->{redis};
    my $callback = $self->__wrap_subcb($cb);
    @args = $BEFORE_FILTERS{all}->($self, @args);
    return $redis->$command(@args, $callback);
}

sub subscribe {
    my $self = shift;
    return $self->__subscribe('subscribe', @_);
}

sub psubscribe {
    my $self = shift;
    return $self->__subscribe('psubscribe', @_);
}

sub unsubscribe {
    my $self = shift;
    return $self->__subscribe('unsubscribe', @_);
}

sub punsubscribe {
    my $self = shift;
    return $self->__subscribe('punsubscribe', @_);
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

If Redis::Namespace doesn't known the command,
call L<command info|http://redis.io/commands/command-info> and guess postions of keys.
It is boolean value.

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
