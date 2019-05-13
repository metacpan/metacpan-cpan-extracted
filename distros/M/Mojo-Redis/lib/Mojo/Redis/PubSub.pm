package Mojo::Redis::PubSub;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::JSON qw(from_json to_json);

use constant DEBUG => $ENV{MOJO_REDIS_DEBUG};

has connection => sub { shift->redis->_connection };
has db         => sub { shift->redis->db };
has reconnect_interval => 1;
has redis              => sub { Carp::confess('redis is requried in constructor') };

sub channels_p {
  shift->db->call_p(qw(PUBSUB CHANNELS), @_);
}

sub json { ++$_[0]{json}{$_[1]} and return $_[0] }

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

  $self->_listen($name) unless @{$self->{chans}{$name} ||= []};
  push @{$self->{chans}{$name}}, $cb;

  return $cb;
}

sub notify {
  my ($self, $name, $payload) = @_;
  $payload = to_json $payload if $self->{json}{$name};
  shift->db->call_p(PUBLISH => $name, $payload);
}

sub numsub_p {
  shift->db->call_p(qw(PUBSUB NUMSUB), @_)->then(sub { +{@{$_[0]}} });
}

sub numpat_p {
  shift->db->call_p(qw(PUBSUB NUMPAT));
}

sub unlisten {
  my ($self, $name, $cb) = @_;
  my $chans = $self->{chans}{$name};

  @$chans = $cb ? grep { $cb ne $_ } @$chans : ();
  unless (@$chans) {
    $self->connection->write_p(($name =~ /\*/ ? 'PUNSUBSCRIBE' : 'UNSUBSCRIBE'), $name);
    delete $self->{chans}{$name};
  }

  return $self;
}

sub _keyspace_key {
  my $args = ref $_[-1] eq 'HASH' ? pop : {};
  my $self = shift;

  local $args->{key} = $_[0] // $args->{key} // '*';
  local $args->{op}  = $_[1] // $args->{op}  // '*';
  local $args->{type} = $args->{type} || ($args->{key} eq '*' ? 'keyevent' : 'keyspace');

  return sprintf '__%s@%s__:%s', $args->{type}, $args->{db} // $self->redis->url->path->[0] // '*',
    $args->{type} eq 'keyevent' ? $args->{op} : $args->{key};
}

sub _listen {
  my ($self, $name) = @_;

  if ($self->{setup}) {
    my $op = $name =~ /\*/ ? 'PSUBSCRIBE' : 'SUBSCRIBE';
    return $self->connection->write_p($op => $name);
  }

  Scalar::Util::weaken($self);
  my $conn         = $self->connection;
  my $reconnecting = delete $self->{reconnecting};

  $self->{setup} = 1;
  $conn->once(close => sub { $self and $self->_reconnect->emit(disconnect => shift) });
  $conn->on(
    response => sub {
      my ($conn, $res) = @_;    # $res = [$type, $name, $payload]
      return unless ref $res eq 'ARRAY' and @$res >= 3;
      $res->[2] = eval { from_json $res->[2] } if $self->{json}{$res->[1]};
      my $keyspace_listen = $self->{keyspace_listen}{$res->[1]};
      for my $cb (@{$self->{chans}{$res->[1]}}) { $self->$cb($keyspace_listen ? [@$res[2, 3]] : $res->[2]) }
    }
  );

  $self->emit(before_connect => $conn);
  return $self unless my @p = map { $self->_listen($_) } keys %{$self->{chans}};
  Mojo::Promise->all(@p)->then(sub { $self->emit(reconnect => $conn) if $reconnecting }, sub { $self->_reconnect });
  return $self;

}

sub _reconnect {
  my $self = shift;
  delete @$self{qw(connection db setup)};

  my $delay = $self->reconnect_interval;
  return $self if $delay < 0 or $self->{reconnecting}++;

  warn qq([Mojo::Redis::PubSub] Reconnecting in ${delay}s...\n) if DEBUG;
  Mojo::IOLoop->timer($delay => sub { $self->_listen });
  return $self;
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
    my ($pubsub, $message) = @_;
    say "superwoman got a message: $message";
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

=head2 reconnect

  $pubsub->on(reconnect => sub { my ($pubsub, $conn) = @_; ... });

Emitted after switching the L</connection> with a new connection. This event
will only happen if L</reconnect_interval> is 0 or more.

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

  $conn   = $pubsub->connection;
  $pubsub = $pubsub->connection(Mojo::Redis->new);

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
    my ($pubsub, $payload) = @_;
    say $payload->{bar};
  });
  $pubsub->notify(foo => {bar => 'I ♥ Mojolicious!'});

=head2 keyspace_listen

  $cb = $pubsub->keyspace_listen($key, $op, sub { my ($pubsub, $message) = @_ }) });
  $cb = $pubsub->keyspace_listen($key, $op, \%args, sub { my ($pubsub, $message) = @_ }) });

Used to listen for keyspace notifications. See L<https://redis.io/topics/notifications>
for more details.

C<$key> C<$op> and C<%args> are optional. C<$key> and C<$op> will default to
"*" and C<%args> can have the following key values:

The channel that will be subscribed to will look like one of these:

  __keyspace@${db}__:$key $op
  __keyevent@${db}__:$op $key

=over 2

=item * db

Default database to listen for events is the database set in
L<Mojo::Redis/url>. "*" is also a valid value, meaning listen for events
happening in all databases.

=item * key

Alternative to passing in C<$key>. Default value is "*".

=item * op

Alternative to passing in C<$op>. Default value is "*".

=item * type

Will default to "keyevent" if C<$key> is "*", and "keyspace" if not. It can
also be set to "key*" for listening to both "keyevent" and "keyspace" events.

=back

=head2 keyspace_unlisten

  $pubsub = $pubsub->keyspace_unlisten(@args);
  $pubsub = $pubsub->keyspace_unlisten(@args, $cb);

Stop listening for keyspace events. See L</keyspace_listen> for details about
keyspace events and what C<@args> can be.

=head2 listen

  $cb = $pubsub->listen($channel => sub { my ($pubsub, $message) = @_ });

Subscribe to a channel, there is no limit on how many subscribers a channel
can have. The returning code ref can be passed on to L</unlisten>.

=head2 notify

  $pubsub->notify($channel => $message);

Send a plain string message to a channel.

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
