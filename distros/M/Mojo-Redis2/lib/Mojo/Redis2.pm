package Mojo::Redis2;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop;
use Mojo::Redis2::Cursor;
use Mojo::Redis2::Server;
use Mojo::URL;
use Mojo::Util;
use Carp ();
use constant DEBUG => $ENV{MOJO_REDIS_DEBUG} || 0;
use constant DEFAULT_PORT => 6379;

our $VERSION = '0.34';

my $PROTOCOL_CLASS = do {
  my $class = $ENV{MOJO_REDIS_PROTOCOL}
    ||= eval "require Protocol::Redis::XS; 'Protocol::Redis::XS'" || 'Protocol::Redis';
  eval "require $class; 1" or die $@;
  $class;
};

has encoding       => 'UTF-8';
has protocol_class => $PROTOCOL_CLASS;

# DEPRECATED
has protocol => sub {
  Mojo::Util::deprecated('protocol is deprecated in favor or protocol_class');
  $_[0]->protocol_class->new(api => 1);
};

sub url { $_[0]->{url} ||= Mojo::URL->new($ENV{MOJO_REDIS_URL} || 'redis://localhost:6379'); }

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{name} = Mojo::Util::steady_time if DEBUG;

  if ($self->{url} and ref $self->{url} eq '') {
    $self->{url} = "redis://$self->{url}" unless $self->{url} =~ /^redis:/;
    $self->{url} = Mojo::URL->new($self->{url});
  }

  $self;
}

sub blpop      { shift->_execute(blpop      => BLPOP      => @_); }
sub brpop      { shift->_execute(brpop      => BRPOP      => @_); }
sub brpoplpush { shift->_execute(brpoplpush => BRPOPLPUSH => @_); }

sub bulk {
  my $self = shift;
  require Mojo::Redis2::Bulk;
  Mojo::Redis2::Bulk->new(_redis => $self);
}

sub client {
  my $self = shift;
  require Mojo::Redis2::Client;
  Mojo::Redis2::Client->new(_redis => $self);
}

sub backend {
  my $self = shift;
  require Mojo::Redis2::Backend;
  Mojo::Redis2::Backend->new(_redis => $self);
}

sub multi {
  my $self       = shift;
  my @attributes = qw( encoding protocol_class url );
  require Mojo::Redis2::Transaction;
  Mojo::Redis2::Transaction->new(map { $_ => $self->$_ } @attributes);
}

sub psubscribe   { shift->_pubsub(PSUBSCRIBE   => @_); }
sub punsubscribe { shift->_pubsub(PUNSUBSCRIBE => @_); }
sub subscribe    { shift->_pubsub(SUBSCRIBE    => @_); }

sub unsubscribe {
  my $self = shift;
  return $self->_pubsub(UNSUBSCRIBE => @_) if ref $_[0] eq 'ARRAY';
  return $self->SUPER::unsubscribe(@_);
}

sub DESTROY { $_[0]->{destroy} = 1; $_[0]->_cleanup; }

sub _basic_operations {
  'append', 'bitcount', 'bitop', 'bitpos', 'decr', 'decrby', 'del', 'echo', 'eval', 'evalsha', 'exists', 'expire',
    'expireat', 'get', 'getbit', 'getrange', 'getset', 'geoadd', 'geodist', 'geohash', 'geopos', 'georadius',
    'georadiusbymember', 'hdel', 'hexists', 'hget', 'hgetall', 'hincrby', 'hincrbyfloat', 'hkeys', 'hlen', 'hmget',
    'hmset', 'hset', 'hsetnx', 'hstrlen', 'hvals', 'incr', 'incrby', 'incrbyfloat', 'keys', 'lindex', 'linsert',
    'llen', 'lpop', 'lpush', 'lpushx', 'lrange', 'lrem', 'lset', 'ltrim', 'mget', 'move', 'mset', 'msetnx', 'persist',
    'pexpire', 'pexpireat', 'pfadd', 'pfcount', 'pfmerge', 'ping', 'psetex', 'pttl', 'publish', 'randomkey', 'rename',
    'renamenx', 'rpop', 'rpoplpush', 'rpush', 'rpushx', 'sadd', 'scard', 'sdiff', 'sdiffstore', 'set', 'setbit',
    'setex', 'setnx', 'setrange', 'sinter', 'sinterstore', 'sismember', 'smembers', 'smove', 'sort', 'spop',
    'srandmember', 'srem', 'strlen', 'sunion', 'sunionstore', 'ttl', 'type', 'zadd', 'zcard', 'zcount', 'zincrby',
    'zinterstore', 'zlexcount', 'zrange', 'zrangebylex', 'zrangebyscore', 'zrank', 'zrem', 'zremrangebylex',
    'zremrangebyrank', 'zremrangebyscore', 'zrevrange', 'zrevrangebylex', 'zrevrangebyscore', 'zrevrank', 'zscore',
    'zunionstore';
}

sub _blocking_group {'blocking'}

sub _cleanup {
  my $self        = shift;
  my $connections = delete $self->{connections};

  delete $self->{pid};

  for my $c (values %$connections) {
    my $loop = $self->_loop($c->{nb}) or next;
    $loop->remove($c->{id}) if $c->{id};
    $self->$_('Premature connection close', []) for grep {$_} map { $_->[0] } @{$c->{waiting}};
  }
}

sub _connect {
  my ($self, $c) = @_;
  my $url      = $self->url;
  my $db       = $url->path->[0];
  my @userinfo = split /:/, +($url->userinfo // '');

  Scalar::Util::weaken($self);
  $c->{protocol} = $self->protocol_class->new(api => 1);
  $c->{name} = "$self->{name}:$c->{group}:$c->{nb}" if DEBUG;
  $c->{id} = $self->_loop($c->{nb})->client(
    {address => $url->host, port => $url->port || DEFAULT_PORT},
    sub {
      my ($loop, $err, $stream) = @_;

      if ($err) {
        delete $c->{id};
        return $self->_error($c, $err);
      }

      warn "[$c->{name}] --- @{[$self->_debug_url($url, $c)]}\n" if DEBUG;

      $stream->timeout(0);
      $stream->on(close => sub { $self and $self->_error($c) });
      $stream->on(error => sub { $self and $self->_error($c, $_[1]) });
      $stream->on(read  => sub { $self and $self->_read($c, $_[1]) });

      # NOTE: unshift() will cause AUTH to be sent before SELECT
      unshift @{$c->{queue}}, [undef, SELECT => $db]          if $db;
      unshift @{$c->{queue}}, [undef, AUTH   => $userinfo[1]] if length $userinfo[1];

      $self->emit(connection => {map { $_ => $c->{$_} } qw( group id nb )});
      $self->_dequeue($c);
    },
  );

  $self;
}

sub _debug_url {
  my $self = shift;
  my $url  = shift->clone;
  my $c    = shift;

  if (my $userinfo = $url->userinfo) {
    $userinfo =~ s!:.*!:******!;
    $url->userinfo($userinfo);
  }

  return $url->query({g => $c->{group}});
}

sub _dequeue {
  my ($self, $c) = @_;
  my $loop   = $self->_loop($c->{nb});
  my $stream = $loop->stream($c->{id}) or return $self;    # stream is not yet connected
  my $queue  = $c->{queue};
  my $buf;

  if (!$queue->[0]) {
    return $self;
  }

  # Make sure connection has not been corrupted while event loop was stopped
  if (!$loop->is_running and $stream->is_readable) {
    $stream->close;
    return $self;
  }

  push @{$c->{waiting}}, shift @$queue;
  $buf = $self->_op_to_command($c);
  do { local $_ = $buf; s!\r\n!\\r\\n!g; warn "[$c->{name}] <<< ($_)\n" } if DEBUG;
  $stream->write($buf);
  $self;
}

sub _error {
  my ($self, $c, $err) = @_;
  my $waiting = $c->{waiting} || $c->{queue};

  warn "[$c->{name}] !!! @{[$err // 'close']}\n" if DEBUG;

  return if $self->{destroy};
  return $self->_requeue($c)->_connect($c) unless defined $err;
  return $self->emit(error => $err) unless @$waiting;
  $self->$_($err, undef) for grep {$_} map { $_->[0] } @$waiting;
}

sub _execute {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $group, @cmd) = @_;

  $self->_cleanup unless ($self->{pid} //= $$) eq $$;    # TODO: Fork safety

  if ($cb) {
    my $c = $self->{connections}{$group} ||= {nb => 1, group => $group};
    push @{$c->{queue}}, [$cb, @cmd];
    return $self->_connect($c) unless $c->{id};
    return $self->_dequeue($c);
  }
  else {
    my $c = $self->{connections}{$self->_blocking_group} ||= {nb => 0, group => $self->_blocking_group};
    my ($err, $res);

    push @{$c->{queue}}, [sub { shift->_loop(0)->stop; ($err, $res) = @_; }, @cmd];
    $c->{id} ? $self->_dequeue($c) : $self->_connect($c);
    $self->_loop(0)->start;
    die "[@cmd] $err" if $err;
    return $res;
  }
}

sub _loop {
  $_[1] ? Mojo::IOLoop->singleton : ($_[0]->{ioloop} ||= Mojo::IOLoop->new);
}

sub _op_to_command {
  my ($self, $c) = @_;
  my $op = $c->{waiting}[-1];
  my ($i, @data);

  for my $token (@$op) {
    next unless $i++;
    $token = Mojo::Util::encode($self->encoding, $token) if $self->encoding;
    push @data, {type => '$', data => $token};
  }

  $c->{protocol}->encode({type => '*', data => \@data});
}

sub _pubsub {
  my $cb = ref $_[-1] eq 'CODE' ? pop : sub { };
  my ($self, $op) = (shift, shift);
  my $channels = ref $_[0] eq 'ARRAY' ? shift : [];

  unless (@$channels) {
    my $method = lc $op;
    $channels = [@_];
    Mojo::Util::deprecated("$method(\@list, ...) is DEPRECATED: Requires an array-ref as first argument.");
  }

  $self->_execute(pubsub => $op => @$channels, $cb);
}

sub _read {
  my ($self, $c, $buf) = @_;
  my $protocol = $c->{protocol};
  my $event;

  do { local $_ = $buf; s!\r\n!\\r\\n!g; warn "[$c->{name}] >>> ($_)\n" } if DEBUG;
  $protocol->parse($buf);

MESSAGE:
  while (my $message = $protocol->get_message) {
    my $data = $self->_reencode_message($message);

    if (ref $data eq 'SCALAR') {
      my $cb = (shift @{$c->{waiting}} || [])->[0];
      $self->$cb($$data, []) if $cb;
    }
    elsif (ref $data eq 'ARRAY' and $data->[0] and $data->[0] =~ /^(p?message)$/i) {
      $event = shift @$data;
      $self->emit($event => reverse @$data);
    }
    else {
      my $cb = (shift @{$c->{waiting}} || [])->[0];
      $self->$cb('', $data) if $cb;
    }

    $self->_dequeue($c);
  }
}

sub _reencode_message {
  my ($self, $message) = @_;
  my ($type, $data)    = @{$message}{qw( type data )};

  if ($type ne '*' and $self->encoding and $data) {
    $data = Encode::decode($self->encoding, $data);
  }

  if ($type eq '-') {
    return \$data;
  }
  elsif ($type ne '*') {
    return $data;
  }
  else {
    return [map { $self->_reencode_message($_); } @$data];
  }
}

sub _requeue {
  my ($self, $c) = @_;

  unshift @{$c->{queue}}, grep { $_->[0] } @{delete $c->{waiting} || []};
  return $self;
}

sub _scan_operations { qw(scan sscan hscan zscan); }

for my $method (__PACKAGE__->_basic_operations) {
  my $op = uc $method;
  eval "sub $method { shift->_execute(basic => $op => \@_); }; 1" or die $@;
}

for my $method (__PACKAGE__->_scan_operations) {
  my $op = uc $method;
  Mojo::Util::monkey_patch(__PACKAGE__,
    $method,
    sub {
      my $self = shift;
      return Mojo::Redis2::Cursor->new(command => [$op => @_])->redis($self);
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis2 - Pure-Perl non-blocking I/O Redis driver

=head1 VERSION

0.34

=head1 DESCRIPTION

L<Mojo::Redis2> is a pure-Perl non-blocking I/O L<Redis|http://redis.io>
driver for the L<Mojolicious> real-time framework.

L<Mojo::Redis2> has not been maintained for a while, and it has some design
flaws that makes it hard to work with. All of this and more is taken care of in
L<Mojo::Redis>.

Want to take over L<Mojo::Redis2>? Contact me on github and I'll let you have it.

I encourage everyone to have a look at L<Mojo::Redis>, and I discourage any new
codebase from using L<Mojo::Redis2>.

=over 2

=item * L<https://github.com/jhthorsen/mojo-redis/issues?utf8=%E2%9C%93&q=is%3Aclosed>

=item * L<https://github.com/jhthorsen/mojo-redis2/issues>

=back

=head1 SYNOPSIS

=head2 Blocking

  use Mojo::Redis2;
  my $redis = Mojo::Redis2->new;

  # Will die() on error.
  $res = $redis->set(foo => "42"); # $res = OK
  $res = $redis->get("foo");       # $res = 42

=head2 Non-blocking

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $redis->ping($delay->begin)->get("foo", $delay->begin);
    },
    sub {
      my ($delay, $ping_err, $ping, $get_err, $get) = @_;
      # On error: $ping_err and $get_err is set to a string
      # On success: $ping = "PONG", $get = "42";
    },
  );

=head2 Pub/sub

L<Mojo::Redis2> can L</subscribe> and re-use the same object to C<publish> or
run other Redis commands, since it can keep track of multiple connections to
the same Redis server. It will also re-use the same connection when you
(p)subscribe multiple times.

  $self->on(message => sub {
    my ($self, $message, $channel) = @_;
  });

  $self->subscribe(["some:channel"], sub {
    my ($self, $err) = @_;

    return $self->publish("myapp:errors" => $err) if $err;
    return $self->incr("subscribed:to:some:channel");
  });

=head2 Mojolicious app

  use Mojolicious::Lite;

  helper redis => sub { shift->stash->{redis} ||= Mojo::Redis2->new; };

  get '/' => sub {
    my $c = shift;

    my $tx = $c->render_later->tx;
    $c->redis->get('some:message', sub {
      my ($redis, $err, $message) = @_;
      $c->render(json => { error => $err, message => $message });
      undef $tx;
    });
  };

  app->start;

=head2 Error handling

C<$err> in this document is a string containing an error message or
empty string on success.

=head1 EVENTS

=head2 connection

  $self->on(connection => sub { my ($self, $info) = @_; ... });

Emitted when a new connection has been established. C<$info> is a hash ref
with:

  {
    group => $str, # basic, blocking, blpop, brpop, brpoplpush, publish, ...
    id => $connection_id,
    nb => $bool, # blocking/non-blocking
  }

Note: The structure of C<$info> is EXPERIMENTAL.

=head2 error

  $self->on(error => sub { my ($self, $err) = @_; ... });

Emitted if an error occurs that can't be associated with an operation.

=head2 message

  $self->on(message => sub {
    my ($self, $message, $channel) = @_;
  });

Emitted when a C<$message> is received on a C<$channel> after it has been
L<subscribed|/subscribe> to.

=head2 pmessage

  $self->on(pmessage => sub {
    my ($self, $message, $channel, $pattern) = @_;
  });

Emitted when a C<$message> is received on a C<$channel> matching a
C<$pattern>, after it has been L<subscribed|/psubscribe> to.

=head1 ATTRIBUTES

=head2 encoding

  $str = $self->encoding;
  $self = $self->encoding('UTF-8');

Holds the character encoding to use for data from/to Redis. Default is
C<UTF-8>. Set to C<undef> to disable encoding/decoding data. Without an
encoding set, Redis expects and returns bytes.

=head2 protocol

DEPRECATED! The protocol object cannot be shared in high load
environments.

=head2 protocol_class

  $str = $self->protocol_class;
  $self = $self->protocol_class('Protocol::Redis::XS');

Holds the class name used to parse/generate Redis messages.
Defaults to L<Protocol::Redis::XS> or L<Protocol::Redis>.

L<Protocol::Redis::XS> need to be installed manually.

=head2 url

  $url = $self->url;

Holds a L<Mojo::URL> object with the location to the Redis server. Default
is C<MOJO_REDIS_URL> or "redis://localhost:6379". The L</url> need to be set
in constructor. Examples:

  Mojo::Redis2->new(url => "redis://x:$auth_key\@$server:$port/$database_index");
  Mojo::Redis2->new(url => "redis://10.0.0.42:6379");
  Mojo::Redis2->new(url => "redis://10.0.0.42:6379/1");
  Mojo::Redis2->new(url => "redis://x:s3cret\@10.0.0.42:6379/1");

=head1 METHODS

In addition to the methods listed in this module, you can call these Redis
methods on C<$self>:

=head3 Connection

echo, ping

=head3 Geo

geoadd, geodist, geohash, geopos, georadius,
georadiusbymember

=head3 Hashes

hdel, hexists, hget, hgetall, hincrby, hincrbyfloat,
hkeys, hlen, hmget, hmset, hset, hsetnx, hstrlen, hvals

=head3 HyperLogLog

pfadd, pfcount, pfmerge

=head3 Keys

del, exists, expire, expireat, keys, move, persist,
pexpire, pexpireat, pttl, randomkey, rename, renamenx,
sort, ttl, type

=head3 Lists

lindex, linsert, llen, lpop, lpush, lpushx, lrange, lrem,
lset, ltrim, rpop, rpoplpush, rpush, rpushx

=head3 PubSub

publish

=head3 Scripting

eval, evalsha

=head3 Sets

sadd, scard, sdiff, sdiffstore, sinter, sinterstore,
sismember, smembers, smove, spop, srandmember, srem,
sunion, sunionstore

=head3 Sorted Sets

zadd, zcard, zcount, zincrby, zinterstore, zlexcount,
zrange, zrangebylex, zrangebyscore, zrank, zrem,
zremrangebylex, zremrangebyrank, zremrangebyscore,
zrevrange, zrevrangebylex, zrevrangebyscore,
zrevrank, zscore, zunionstore

=head3 Strings

append, bitcount, bitop, bitpos, decr, decrby, get,
getbit, getrange, getset, incr, incrby, incrbyfloat,
mget, mset, msetnx, psetex, set, setbit, setex, setnx,
setrange, strlen


See L<http://redis.io/commands> for details.

=head2 new

  $self = Mojo::Redis2->new(...);

Object constructor. Makes sure L</url> is an object.

=head2 blpop

  $self = $self->blpop(@keys, $timeout, sub { my ($self, $err, $res) = @_; });

This method will issue the BLPOP command on the Redis server, but in its
own connection. This means that C<$self> can still be used to run other
L<commands|/METHODS> instead of being blocking.

Note: This method will only work in a non-blocking environment.

See also L<http://redis.io/commands/blpop>.

=head2 brpop

  $self = $self->brpop(@keys, $timeout, sub { my ($self, $err, $res) = @_; });

Follows the same API as L</blpop>.
See also L<http://redis.io/commands/brpop>.

=head2 brpoplpush

  $self = $self->brpoplpush($from => $to, $timeout, sub { my ($self, $err, $res) = @_; });

Follows the same API as L</blpop>.
See also L<http://redis.io/commands/brpoplpush>.

=head2 bulk

  $obj = $self->bulk;

Returns a L<Mojo::Redis2::Bulk> object which can be used to group Redis
operations.

=head2 client

  $self->client->$method(@args);

Run "CLIENT" commands using L<Mojo::Redis2::Client>.

=head2 backend

  $self->backend->$method(@args);

Run server commands (CONFIG, INFO, SAVE, ...) using L<Mojo::Redis2::Backend>.

=head2 multi

  $txn = $self->multi;

This method does not perform the "MULTI" Redis command, but returns a
L<Mojo::Redis2::Transaction> object instead.

The L<Mojo::Redis2::Transaction> object is a subclass of L<Mojo::Redis2>,
which will run all the Redis commands inside a transaction.

=head2 psubscribe

  $self = $self->psubscribe(\@patterns, sub { my ($self, $err, $res) = @_; ... });

Used to subscribe to channels that match C<@patterns>. Messages arriving over a
matching channel name will result in L</pmessage> events.

See L<http://redis.io/topics/pubsub> for details.

=head2 punsubscribe

  $self = $self->punsubscribe(\@patterns, sub { my ($self, $err, $res) = @_; ... });

The reverse of L</psubscribe>.
See L<http://redis.io/topics/pubsub> for details.

=head2 scan, hscan, sscan, zscan

  $cur = $self->scan(0, MATCH => 'namesoace*', COUNT => 15);
  $cur = $self->hscan('hash.key', 0, MATCH => 'pref.*');
  $cur = $self->sscan('set.key', 0);
  $cur = $self->zscan('zset.key', 0);

  $res = $cur->next();

Methods from C<SCAN> family will return L<Mojo::Redis2::Cursor> object to
iterate over elements collection.

=head2 subscribe

  $self = $self->subscribe(\@channels, sub { my ($self, $err, $res) = @_; ... });

Used to subscribe to C<@channels>. Messages arriving over a channel will
result in L</message> events.

See L<http://redis.io/topics/pubsub> for details.

=head2 unsubscribe

  $self = $self->unsubscribe(\@channels, sub { my ($self, $err, $res) = @_; ... });
  $self = $self->unsubscribe($event);
  $self = $self->unsubscribe($event, $cb);

The reverse of L</subscribe>. It will also call L<Mojo::EventEmitter/unsubscribe>
unless the first argument is an array-ref of C<@channels>.

See L<http://redis.io/topics/pubsub> for details.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Andre Parker

Ben Tyler - C<benjamin.tyler@gmail.com>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Mike Magowan - C<mike@magowan.co.uk>

=cut
