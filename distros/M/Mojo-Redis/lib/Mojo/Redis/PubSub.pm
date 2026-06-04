package Mojo::Redis::PubSub;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::JSON qw(from_json to_json);

use constant DEBUG => $ENV{MOJO_REDIS_DEBUG};

has connection => sub {
  my $self = shift;
  my $conn = $self->redis->_connection;

  Scalar::Util::weaken($self);
  for my $name (qw(close error response)) {
    my $handler = "_on_$name";
    $conn->on($name => sub { $self and $self->$handler(@_) });
  }

  return $conn;
};

has db => sub {
  my $self = shift;
  my $db   = $self->redis->db;
  Scalar::Util::weaken($db->{redis});
  return $db;
};

has reconnect_interval => 1;
has redis              => sub { Carp::confess('redis is requried in constructor') };

sub channels_p { shift->db->call_p(qw(PUBSUB CHANNELS), @_) }
sub json       { ++$_[0]{json}{$_[1]} and return $_[0] }

sub keyspace_listen {
  my ($self, $cb) = (shift, pop);
  my $key = $self->_keyspace_key(@_);
  $self->{keyspace_listen}{$key} = 1;
  return $self->listen($key, $cb);
}

sub keyspace_unlisten {
  my ($self, $cb) = (shift, ref $_[-1] eq 'CODE' ? pop : undef);
  return $self->unlisten($self->_keyspace_key(@_), $cb);
}

sub listen {
  my ($self, $name, $cb) = @_;

  unless (@{$self->{chans}{$name} ||= []}) {
    Mojo::IOLoop->remove(delete $self->{reconnect_tid}) if $self->{reconnect_tid};
    $self->_write([($name =~ /\*/ ? 'PSUBSCRIBE' : 'SUBSCRIBE') => $name]);
  }

  push @{$self->{chans}{$name}}, $cb;
  return $cb;
}

sub notify_p {
  my ($self, $name, $payload) = @_;
  $payload = to_json $payload if $self->{json}{$name};
  return $self->db->call_p(PUBLISH => $name, $payload);
}

sub notify   { shift->notify_p(@_)->wait }
sub numpat_p { shift->db->call_p(qw(PUBSUB NUMPAT)) }
sub numsub_p { shift->db->call_p(qw(PUBSUB NUMSUB), @_)->then(\&_flatten) }

sub unlisten {
  my ($self, $name, $cb) = @_;
  my $chans = $self->{chans}{$name};

  @$chans = $cb ? grep { $cb ne $_ } @$chans : ();
  unless (@$chans) {
    my $conn = $self->connection;
    $conn->write(($name =~ /\*/ ? 'PUNSUBSCRIBE' : 'UNSUBSCRIBE'), $name) if $conn->is_connected;
    delete $self->{chans}{$name};
  }

  return $self;
}

sub _flatten { +{@{$_[0]}} }

sub _keyspace_key {
  my $args = ref $_[-1] eq 'HASH' ? pop : {};
  my $self = shift;

  local $args->{key}  = $_[0] // $args->{key} // '*';
  local $args->{op}   = $_[1] // $args->{op}  // '*';
  local $args->{type} = $args->{type} || ($args->{key} eq '*' ? 'keyevent' : 'keyspace');

  return sprintf '__%s@%s__:%s', $args->{type}, $args->{db} // $self->redis->url->path->[0] // '*',
    $args->{type} eq 'keyevent' ? $args->{op} : $args->{key};
}

sub _on_close {
  my $self = shift;
  $self->emit(disconnect => $self->connection);

  my $delay = $self->reconnect_interval;
  return $self if $delay < 0 or $self->{reconnect_tid};

  warn qq([Mojo::Redis::PubSub] Reconnecting in ${delay}s...\n) if DEBUG;
  Scalar::Util::weaken($self);
  $self->{reconnect}     = 1;
  $self->{reconnect_tid} = Mojo::IOLoop->timer($delay => sub { $self and $self->_reconnect });
  return $self;
}

sub _on_error { $_[0]->emit(error => $_[2]) }

sub _on_response {
  my ($self, $conn, $res) = @_;
  $self->emit(reconnect => $conn) if delete $self->{reconnect};

  # $res = [pmessage => $name, $channel, $data]
  # $res = [message  =>        $channel, $data]

  return                    unless ref $res eq 'ARRAY';
  return $self->emit(@$res) unless $res->[0] =~ m!^p?message$!i;

  my ($name)          = $res->[0] eq 'pmessage' ? splice @$res, 1, 1 : ($res->[1]);
  my $keyspace_listen = $self->{keyspace_listen}{$name};

  local $@;
  $res->[2] = eval { from_json $res->[2] } if $self->{json}{$name};
  for my $cb (@{$self->{chans}{$name} || []}) {
    $self->$cb($keyspace_listen ? [@$res[1, 2]] : $res->[2], $res->[1]);
  }
}

sub _reconnect {
  my $self = shift;
  delete $self->{$_} for qw(before_connect connection reconnect_tid);
  $self->_write(map { [(/\*/ ? 'PSUBSCRIBE' : 'SUBSCRIBE') => $_] } keys %{$self->{chans}});
}

sub _write {
  my ($self, @commands) = @_;
  my $conn = $self->connection;
  $self->emit(before_connect => $conn) unless $self->{before_connect}++;
  $conn->write(@$_) for @commands;
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis::PubSub - Publish and subscribe to Redis messages

=head1 SYNOPSIS

  use Mojo::Redis;

  my $redis  = Mojo::Redis->new;
  my $pubsub = $redis->pubsub;

  $pubsub->listen("user:superwoman:messages" => sub {
    my ($pubsub, $message, $channel) = @_;
    say "superwoman got a message '$message' from channel '$channel'";
  });

  $pubsub->notify("user:batboy:messages", "How are you doing?");

See L<https://github.com/jhthorsen/mojo-redis/blob/master/examples/chat.pl>
for example L<Mojolicious> application.

=head1 DESCRIPTION

L<Mojo::Redis::PubSub> is an implementation of the Redis Publish/Subscribe
messaging paradigm. This class has the same API as L<Mojo::Pg::PubSub>, so
you can easily switch between the backends.

This object holds one connection for receiving messages, and one connection
for sending messages. They are created lazily the first time L</listen> or
L</notify> is called. These connections does not affect the connection pool
for L<Mojo::Redis>.

See L<pubsub|https://redis.io/topics/pubsub> for more details.

=head1 EVENTS

=head2 before_connect

  $pubsub->on(before_connect => sub { my ($pubsub, $conn) = @_; ... });

Emitted before L</connection> is connected to the redis server. This can be
useful if you want to gather the L<CLIENT ID|https://redis.io/commands/client-id>
or run other commands before it goes into subscribe mode.

=head2 disconnect

  $pubsub->on(disconnect => sub { my ($pubsub, $conn) = @_; ... });

Emitted after L</connection> is disconnected from the redis server.

=head2 psubscribe

  $pubsub->on(psubscribe => sub { my ($pubsub, $channel, $success) = @_; ... });

Emitted when the server responds to the L</listen> request and/or when
L</reconnect> resends psubscribe messages.

This event is EXPERIMENTAL.

=head2 reconnect

  $pubsub->on(reconnect => sub { my ($pubsub, $conn) = @_; ... });

Emitted after switching the L</connection> with a new connection. This event
will only happen if L</reconnect_interval> is 0 or more.

=head2 subscribe

  $pubsub->on(subscribe => sub { my ($pubsub, $channel, $success) = @_; ... });

Emitted when the server responds to the L</listen> request and/or when
L</reconnect> resends subscribe messages.

This event is EXPERIMENTAL.

=head1 ATTRIBUTES

=head2 db

  $db = $pubsub->db;

Holds a L<Mojo::Redis::Database> object that will be used to publish messages
or run other commands that cannot be run by the L</connection>.

=head2 connection

  $conn = $pubsub->connection;

Holds a L<Mojo::Redis::Connection> object that will be used to subscribe to
channels.

=head2 reconnect_interval

  $interval = $pubsub->reconnect_interval;
  $pubsub   = $pubsub->reconnect_interval(1);
  $pubsub   = $pubsub->reconnect_interval(0.1);
  $pubsub   = $pubsub->reconnect_interval(-1);

The amount of time in seconds to wait to L</reconnect> after disconnecting.
Default is 1 (second). L</reconnect> can be disabled by setting this to a
negative value.

=head2 redis

  $conn   = $pubsub->redis;
  $pubsub = $pubsub->redis(Mojo::Redis->new);

Holds a L<Mojo::Redis> object used to create the connections to talk with Redis.

=head1 METHODS

=head2 channels_p

  $promise = $pubsub->channels_p->then(sub { my $channels = shift });
  $promise = $pubsub->channels_p("pat*")->then(sub { my $channels = shift });

Lists the currently active channels. An active channel is a Pub/Sub channel
with one or more subscribers (not including clients subscribed to patterns).

=head2 json

  $pubsub = $pubsub->json("foo");

Activate automatic JSON encoding and decoding with L<Mojo::JSON/"to_json"> and
L<Mojo::JSON/"from_json"> for a channel.

  # Send and receive data structures
  $pubsub->json("foo")->listen(foo => sub {
    my ($pubsub, $payload, $channel) = @_;
    say $payload->{bar};
  });
  $pubsub->notify(foo => {bar => 'I ♥ Mojolicious!'});

=head2 keyspace_listen

  $cb = $pubsub->keyspace_listen(\%args,              sub { my ($pubsub, $message) = @_ }) });
  $cb = $pubsub->keyspace_listen({key => "cool:key"}, sub { my ($pubsub, $message) = @_ }) });
  $cb = $pubsub->keyspace_listen({op  => "del"},      sub { my ($pubsub, $message) = @_ }) });

Used to listen for keyspace notifications. See L<https://redis.io/topics/notifications>
for more details. The channel that will be subscribed to will look like one of
these:

  __keyspace@${db}__:$key $op
  __keyevent@${db}__:$op $key

This means that "key" and "op" is mutually exclusive from the list of
parameters below:

=over 2

=item * db

Default database to listen for events is the database set in
L<Mojo::Redis/url>. "*" is also a valid value, meaning listen for events
happening in all databases.

=item * key

Alternative to passing in C<$key>. Default value is "*".

=item * op

Alternative to passing in C<$op>. Default value is "*".

=back

=head2 keyspace_unlisten

  $pubsub = $pubsub->keyspace_unlisten(@args);
  $pubsub = $pubsub->keyspace_unlisten(@args, $cb);

Stop listening for keyspace events. See L</keyspace_listen> for details about
keyspace events and what C<@args> can be.

=head2 listen

  $cb = $pubsub->listen($channel => sub { my ($pubsub, $message, $channel) = @_ });

Subscribe to an exact channel name
(L<SUBSCRIBE|https://redis.io/commands/subscribe>) or a channel name with a
pattern (L<PSUBSCRIBE|https://redis.io/commands/psubscribe>). C<$channel> in
the callback will be the exact channel name, without any pattern. C<$message>
will be the data published to that the channel.

The returning code ref can be passed on to L</unlisten>.

=head2 notify

  $pubsub->notify($channel => $message);

Send a plain string message to a channel. This method is the same as:

  $pubsub->notify_p($channel => $message)->wait;

=head2 notify_p

  $p = $pubsub->notify_p($channel => $message);

Send a plain string message to a channel and returns a L<Mojo::Promise> object.

=head2 numpat_p

  $promise = $pubsub->channels_p->then(sub { my $int = shift });

Returns the number of subscriptions to patterns (that are performed using the
PSUBSCRIBE command). Note that this is not just the count of clients
subscribed to patterns but the total number of patterns all the clients are
subscribed to.

=head2 numsub_p

  $promise = $pubsub->numsub_p(@channels)->then(sub { my $channels = shift });

Returns the number of subscribers (not counting clients subscribed to
patterns) for the specified channels as a hash-ref, where the keys are
channel names.

=head2 unlisten

  $pubsub = $pubsub->unlisten($channel);
  $pubsub = $pubsub->unlisten($channel, $cb);

Unsubscribe from a channel.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
