package Mojo::Redis::PubSub;
use Mojo::Base 'Mojo::EventEmitter';

has connection     => sub { shift->redis->_connection };
has redis          => sub { Carp::confess('redis is requried in constructor') };
has _db_connection => sub { shift->redis->_connection };

sub channels_p {
  shift->_db_connection->write_p(qw(PUBSUB CHANNELS), @_)->then(sub { +[@_] });
}

sub listen {
  my ($self, $name, $cb) = @_;
  my $op = $name =~ /\*/ ? 'PSUBSCRIBE' : 'SUBSCRIBE';

  Scalar::Util::weaken($self);
  $self->connection->write_p($op => $name)->then(sub { $self->_setup }) unless @{$self->{chans}{$name} ||= []};
  push @{$self->{chans}{$name}}, $cb;

  return $cb;
}

sub notify {
  shift->_db_connection->write_p(PUBLISH => @_);
}

sub numsub_p {
  shift->_db_connection->write_p(qw(PUBSUB NUMSUB), @_)->then(sub { +{@_} });
}

sub numpat_p {
  shift->_db_connection->write_p(qw(PUBSUB NUMPAT));
}

sub unlisten {
  my ($self, $name, $cb) = @_;
  my $chan = $self->{chans}{$name};
  my $op = $name =~ /\*/ ? 'PUNSUBSCRIBE' : 'UNSUBSCRIBE';

  @$chan = $cb ? grep { $cb ne $_ } @$chan : ();
  $self->connection->write_p($op => $name) and delete $self->{chans}{$name} unless @$chan;

  return $self;
}

sub _setup {
  my $self = shift;
  return if $self->{cb};

  Scalar::Util::weaken($self);
  $self->{cb} = $self->connection->on(
    response => sub {
      my ($conn, $type, $name, $payload) = @_;
      for my $cb (@{$self->{chans}{$name}}) { $self->$cb($payload) }
    }
  );
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

=head1 DESCRIPTION

L<Mojo::Redis::PubSub> is an implementation of the Redis Publish/Subscribe
messaging paradigm. This class has the same API as L<Mojo::Pg::PubSub>, so
you can easily switch between the backends.

This object holds one connection for receiving messages, and one connection
for sending messages. They are created lazily the first time L</listen> or
L</notify> is called. These connections does not affect the connection pool
for L<Mojo::Redis>.

See L<pubsub|https://redis.io/topics/pubsub> for more details.

=head1 ATTRIBUTES

=head2 connection

  $conn = $self->connection;
  $self = $self->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis::Connection> object.

=head2 redis

  $conn = $self->connection;
  $self = $self->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis> object used to create the connections to talk with Redis.

=head1 METHODS

=head2 channels_p

  $promise = $self->channels_p->then(sub { my $channels = shift });
  $promise = $self->channels_p("pat*")->then(sub { my $channels = shift });

Lists the currently active channels. An active channel is a Pub/Sub channel
with one or more subscribers (not including clients subscribed to patterns).

=head2 listen

  $cb = $self->listen($channel => sub { my ($self, $message) = @_ });

Subscribe to a channel, there is no limit on how many subscribers a channel
can have. The returning code ref can be passed on to L</unlisten>.

=head2 notify

  $self->notify($channel => $message);

Send a plain string message to a channel.

=head2 numpat_p

  $promise = $self->channels_p->then(sub { my $int = shift });

Returns the number of subscriptions to patterns (that are performed using the
PSUBSCRIBE command). Note that this is not just the count of clients
subscribed to patterns but the total number of patterns all the clients are
subscribed to.

=head2 numsub_p

  $promise = $self->numsub_p(@channels)->then(sub { my $channels = shift });

Returns the number of subscribers (not counting clients subscribed to
patterns) for the specified channels as a hash-ref, where the keys are
channel names.

=head2 unlisten

  $self = $self->unlisten($channel);
  $self = $self->unlisten($channel, $cb);

Unsubscribe from a channel.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
