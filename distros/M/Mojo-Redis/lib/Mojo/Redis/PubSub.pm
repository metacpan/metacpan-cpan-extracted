package Mojo::Redis::PubSub;
use Mojo::Base 'Mojo::EventEmitter';

has connection     => sub { shift->redis->_connection };
has redis          => sub { Carp::confess('redis is requried in constructor') };
has _db_connection => sub { shift->redis->_connection };

sub channels_p {
  shift->_db_connection->write_p(qw(PUBSUB CHANNELS), @_);
}

sub keyspace_listen {
  my ($self, $cb) = (shift, pop);
  return $self->listen($self->_keyspace_key(@_), $cb);
}

sub keyspace_unlisten {
  my ($self, $cb) = (shift, ref $_[-1] eq 'CODE' ? pop : undef);
  return $self->unlisten($self->_keyspace_key(@_), $cb);
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
  shift->_db_connection->write_p(qw(PUBSUB NUMSUB), @_)->then(sub { +{@{$_[0]}} });
}

sub numpat_p {
  shift->_db_connection->write_p(qw(PUBSUB NUMPAT));
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

  local $args->{key}  = $_[0] // $args->{key} // '*';
  local $args->{op}   = $_[1] // $args->{op} // '*';
  local $args->{type} = $args->{type} || ($args->{key} eq '*' ? 'keyevent' : 'keyspace');

  return sprintf '__%s@%s__:%s %s', $args->{type}, $args->{db} // $self->redis->url->path->[0] // '',
    $args->{type} eq 'keyevent' ? (@$args{qw(op key)}) : (@$args{qw(key op)});
}

sub _setup {
  my $self = shift;
  return if $self->{cb};

  Scalar::Util::weaken($self);
  $self->{cb} = $self->connection->on(
    response => sub {
      my ($conn, $res) = @_;    # $res = [$type, $name, $payload]
      for my $cb (@{$self->{chans}{$res->[1]}}) { $self->$cb($res->[2]) }
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

=head2 keyspace_listen

  $cb = $self->keyspace_listen($key, $op, sub { my ($self, $message) = @_ }) });
  $cb = $self->keyspace_listen($key, $op, \%args, sub { my ($self, $message) = @_ }) });

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

  $self = $self->keyspace_unlisten(@args);
  $self = $self->keyspace_unlisten(@args, $cb);

Stop listening for keyspace events. See L</keyspace_listen> for details about
keyspace events and what C<@args> can be.

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
