package Mojo::Redis2::Bulk;
use Mojo::Base -base;
use Mojo::Collection;

require Mojo::Redis2;

has _redis => undef;

sub execute {
  my ($self, $cb) = @_;
  my $redis = $self->_redis;
  my @ops   = @{delete $self->{queue} || []};
  my $err   = Mojo::Collection->new;
  my $res   = [];
  my (@err, @res);

  my $collector = sub {
    push @$err, $_[1];
    push @$res, $_[2];
    $self->$cb($err, $res) if @ops == @$res;    # done
  };

  $redis->_execute(@$_, $collector) for @ops;

  return $self if $cb;
  $cb = sub { $redis->_loop(1)->stop };
  $redis->_loop(1)->start;
  die $err->join('. ') if $err->compact->size > 0;
  return $res;
}

for my $method (Mojo::Redis2->_basic_operations) {
  my $op = uc $method;
  eval "sub $method { my \$self = shift; push \@{ \$self->{queue} }, [basic => $op => \@_]; \$self; }; 1" or die $@;
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis2::Bulk - Mojo::Redis2 bulk operations

=head1 DESCRIPTION

L<Mojo::Redis2::Bulk> allow many L<Mojo::Redis2> operations to be grouped
into one serialized operation. This can help you avoid crazy many callback
arguments.

=head1 SYNOPSIS

  use Mojo::Redis2;
  my $redis = Mojo::Redis2->new;
  my $bulk = $redis->bulk;

  $res = $bulk->set(foo => 123)->get("foo")->execute;

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $bulk->set(foo => 123)->get("foo")->execute($delay->begin);
    },
    sub {
      my ($delay, $err, $res) = @_;
      $self->render(json => {
        err => $err->compact->join('. '),
        res => $res,
      });
    },
  );

In both the sync and async examples above, C<$res> will contain on success:

  [
    "OK",
    123,
  ];

C<$err> on the other hand will be a L<Mojo::Collection> object with
all one element for each error message.

=head1 METHODS

In addition to the methods listed in this module, you can call these Redis
methods on C<$self>:

append, bitcount, bitop, bitpos, decr, decrby, del, echo, eval, evalsha, exists,
expire, expireat, geoadd, geodist, geohash, geopos, georadius, georadiusbymember,
get, getbit, getrange, getset, hdel, hexists, hget, hgetall, hincrby, hincrbyfloat,
hkeys, hlen, hmget, hmset, hset, hsetnx, hstrlen, hvals, incr, incrby, incrbyfloat,
keys, lindex, linsert, llen, lpop, lpush, lpushx, lrange, lrem, lset, ltrim, mget,
move, mset, msetnx, persist, pexpire, pexpireat, pfadd, pfcount, pfmerge, ping,
psetex, pttl, publish, randomkey, rename, renamenx, rpop, rpoplpush, rpush, rpushx,
sadd, scard, sdiff, sdiffstore, set, setbit, setex, setnx, setrange, sinter,
sinterstore, sismember, smembers, smove, sort, spop, srandmember, srem, strlen,
sunion, sunionstore, ttl, type, zadd, zcard, zcount, zincrby, zinterstore, zlexcount,
zrange, zrangebylex, zrangebyscore, zrem, zremrangebylex, zremrangebyrank,
zremrangebyscore, zrank, zrevrange, zrevrangebylex, zrevrangebyscore, zrevrank,
zscore, zunionstore

=head2 execute

  $res = $self->execute;
  $self = $self->execute(sub { my ($self, $err, $res) = @_; });

Will execute all the queued Redis operations.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
