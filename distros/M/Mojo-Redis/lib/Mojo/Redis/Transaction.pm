package Mojo::Redis::Transaction;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::Redis::Database;

has connection => sub { shift->redis->_dequeue };
has redis      => sub { Carp::confess('redis is required in constructor') };

Mojo::Redis::Database->_add_bnp_method($_)  for qw(unwatch watch);
Mojo::Redis::Transaction->_add_q_method($_) for @Mojo::Redis::Database::BASIC_COMMANDS;

sub discard {
  my ($self, $cb) = @_;
  $self->{queue} = [];
  return $self->tap($cb, '', 'OK') if $cb;
  return 'OK';
}

sub discard_p {
  my $self = shift;
  $self->{queue} = [];
  return Mojo::Promise->new->resolve('OK');
}

sub exec {
  my ($self, $cb) = @_;

  local $self->{connection} = $cb ? $self->connection : $self->redis->_blocking_connection;
  my $p = $self->exec_p;

  # Non-Blocking
  if ($cb) {
    $p->then(sub { $self->$cb('', @_) })->catch(sub { $self->$cb(shift, []) })->wait;
    return $self;
  }

  # Blocking
  my ($err, $res);
  $p->then(sub { $res = shift })->catch(sub { $err = shift })->wait;
  die $err if $err;
  return $res;
}

sub exec_p {
  my $self  = shift;
  my $queue = delete $self->{queue};
  my $conn  = $self->connection;

  unshift @$queue, [undef, 'MULTI', undef];
  my @process = map {
    my $cb = shift @$_;
    $conn->write_q(@$_);
    $cb;
  } @$queue;

  return $conn->write_p('EXEC')->then(sub {
    return [map { my $cb = shift @process; $cb ? $cb->($_) : $_; } @_];
  });
}

sub multi {
  my ($self, $cb) = @_;
  return $self->tap($cb, '', 'OK') if $cb;
  return 'OK';
}

sub multi_p {
  my $self = shift;
  return Mojo::Promise->new->resolve('OK');
}

sub _add_q_method {
  my ($class, $method) = @_;
  my $caller  = caller;
  my $op      = uc $method;
  my $process = Mojo::Promise::Database->can("_process_$method");

  Mojo::Util::monkey_patch(
    $caller, $method,
    sub {
      my $self = shift;
      push @{$self->{queue}}, [$process, $op, @_, undef];
      return $self;
    }
  );
}

sub DESTROY {
  my $self = shift;
  return unless (my $redis = $self->redis) && (my $conn = $self->connection);
  $redis->_enqueue($conn);
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis::Transaction - Transaction support for Redis

=head1 SYNOPSIS

  my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
  my $txn   = $redis->txn;

  $txn->set($key => 123)
     ->get($key)
     ->incr($key)
     ->incrby($key => -10)
     ->exec_p
     ->then(sub {
       my ($set, $get, $incr, $incrby) = @{$_[0]};
     });

=head1 DESCRIPTION

L<Mojo::Redis::Transaction> provides most of the same methods as
L<Mojo::Redis::Database>, but will issue the commands inside an atomic
transaction.

See L<https://redis.io/topics/transactions> for more details about how Redis
handle transactions.

This class is currently EXPERIMENTAL, and might change without warning.

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

This class has most of the methods documented in L<Mojo::Redis::Database>,
but the methods (such as C<set()>, C<incr()>, ...) will not send a command to
Redis, but rather build up a command queue that is sent when calling L</exec>
or L</exec_p>.

Note that this might change in the future.

=head2 discard

  $self = $self->discard(sub { my ($self, $err, $res) = @_ });
  $res  = $self->discard;

This method does not send any command to the Redis server. The method will
simply empty the command queue.

Note that this might change in future releases.

=head2 discard_p

  $promise = $self->discard_p;

Same as L</discard>, but returns a L<Mojo::Promise>.

=head2 exec

  $self = $self->exec(sub { my ($self, $err, $res) = @_ });
  $res  = $self->exec;

Will start a transaction using C<MULTI>, run all the commands queued and then
commit at the end using C<EXEC>.

=head2 exec_p

  $promise = $self->exec_p;

Same as L</exec>, but returns a L<Mojo::Promise>.

=head2 multi

  $self = $self->multi(sub { my ($self, $err, $res) = @_ });
  $res  = $self->multi;

Note that this might change in future releases.

=head2 multi_p

  $promise = $self->multi_p;

Same as L</multi>, but returns a L<Mojo::Promise>.

=head2 unwatch

  $self = $self->unwatch(sub { my ($self, $err, $res) = @_ });
  $res  = $self->unwatch;

Forget about all watched keys.

See L<https://redis.io/commands/unwatch> for more information.

=head2 unwatch_p

  $promise = $self->unwatch_p($key);

Same as L</unwatch>, but returns a L<Mojo::Promise>.

=head2 watch

  $self = $self->watch($key, sub { my ($self, $err, $res) = @_ });
  $res  = $self->watch($key);

Watch the given keys to determine execution of the MULTI/EXEC block.

See L<https://redis.io/commands/watch> for more information.

=head2 watch_p

  $promise = $self->watch_p($key);

Same as L</watch>, but returns a L<Mojo::Promise>.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
