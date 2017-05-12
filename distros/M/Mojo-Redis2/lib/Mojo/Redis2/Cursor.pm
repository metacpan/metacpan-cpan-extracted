package Mojo::Redis2::Cursor;
use Mojo::Base '-base';

has 'redis';
has command => sub { ['SCAN', 0] };
has _cursor_pos => 1;

sub again {
  my $self = shift;
  $self->command->[$self->_cursor_pos] = 0;
  delete $self->{_finished};
  return $self;
}

sub all {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;

  my $list = [];

  # non-blocking
  if ($cb) {

    # __SUB__ available only from 5.16
    my $wrapper;
    $wrapper = sub {
      push @$list, @{$_[2] // []};
      return $self->$cb($_[1], $list) if $_[0]->{_finished};
      $self->next($wrapper);
    };
    return $self->next(@_ => $wrapper);
  }

  # blocking
  else {
    while (my $r = $self->next(@_)) { push @$list, @$r }
    return $list;
  }
}

sub finished { !!shift->{_finished} }

sub hgetall {
  my $cur = shift->_clone('HSCAN', shift, 0);
  return $cur->all(@_);
}

sub hkeys {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $cur = shift->_clone('HSCAN' => shift, 0, @_);
  my $wrapper = sub {
    my $keys = [grep { $a = !$a } @{$_[2] || []}];
    return $cur->$cb($_[1], $keys);
  };
  my $resp = $cur->all($cb ? ($wrapper) : ());
  return $resp if $cb;
  $cb = sub { $_[2] };
  return $wrapper->(undef, '', $resp);
}

sub keys {
  my $cur = shift->_clone('SCAN', 0);
  unshift @_, 'MATCH' if $_[0] && !ref $_[0];
  return $cur->all(@_);
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->_cursor_pos($self->command->[0] eq 'SCAN' ? 1 : 2);
  return $self;
}

sub next {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;

  return undef if $self->{_finished};

  my ($command, $pos) = ($self->command, $self->_cursor_pos);
  if (@_) { splice @$command, $pos + 1, 4, @_ }
  my $wrapper = sub {
    my (undef, $err, $resp) = @_;
    $command->[$pos] = (my $cur = $resp->[0] // 0);
    $self->{_finished} = 1 if $cur == 0;
    return $self->$cb($err, $resp->[1]);
  };

  my $resp = $self->redis->_execute(basic => @$command, $cb ? ($wrapper) : ());
  return $resp if $cb;
  $cb = sub { $_[2] };
  return $wrapper->(undef, '', $resp);
}

sub smembers {
  my $cur = shift->_clone('SSCAN', shift, 0);
  return $cur->all(@_);
}

sub _clone {
  my $self = shift;
  return $self->new(command => [@_])->redis($self->redis);
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis2::Cursor - Cursor iterator for SCAN commands.

=head1 SYNOPSIS

  use Mojo::Redis2;
  use Mojo::Redis2::Cursor;

  my $redis = Mojo::Redis2->new();
  my $cursor
    = Mojo::Redis2::Cursor->new('SCAN', match => 'mynamespace*')->redis($redis);

  # blocking
  while (my $r = $cursor->next) { say join "\n", @$r }

  # or non-blocking
  use feature 'current_sub';
  $cursor->next(
    sub {
      my ($cur, $err, $r) = @_;
      say join "\n", @$r;
      return Mojo::IOLoop->stop() unless $cur->next(__SUB__);
    }
  );
  Mojo::IOLoop->start();


=head1 DESCRIPTION

L<Mojo::Redis2::Cursor> is an iterator object for C<SCAN> family commands.

=head1 ATTRIBUTES

=head2 command

  $arrayref = $self->command;

Holds the command that is issued to the redis server, but without updated index
information.

=head2 redis

  my $redus = $cursor->redis;
  $cursor->redis(Mojo::Redis2->new());

Redis object to work with.

=head1 METHODS

L<Mojo::Redis2::Cursor> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 again

  $cursor->again();
  my $res = $cursor->again->all();

Reset cursor to start iterating from the beginning.

=head2 all

  my $keys = $cursor->all(COUNT => 5);
  $cursor->all(sub {
    my ($cur, $err, $res) = @_;
  });

Repeatedly call L</next> to fetch all matching elements. Optional
arguments will be passed along.

In case of error will return all data fetched so far.

=head2 finished

  my $is_finished = $cursor->finished();

Indicate that full iteration had been made and no additional elements can be
fetched.

=head2 hgetall

  my $hash = $redis2->scan->hgetall('redis.key');
  $hash = $cursor->hgetall('redis.key');
  $cursor->hgetall('redis.key' => sub {...});

Implements standard C<HGETALL> command using C<HSCAN>.

=head2 hkeys

  my $keys = $redis2->scan->hkeys('redis.key');
  $keys = $cursor->hkeys('redis.key');
  $cursor->hkeys('redis.key' => sub {...});

Implements standard C<HKEYS> command using C<HSCAN>.

=head2 keys

  my $keys = $redis2->scan->keys;
  $keys = $cursor->keys('*');
  $cursor->keys('*' => sub {
    my ($cur, $err, $keys) = @_;
    ...
  });

Implements standard C<KEYS> command using C<SCAN>.

=head2 new

  my $cursor  = Mojo::Redis2::Cursor->new(
    command => ['SCAN', 0, MATCH => 'namespace*']);
  $cursor = Mojo::Redis2::Cursor->new(
    command => [ZSCAN => 'redis.key', 0, COUNT => 15]);

Object constructor. Follows same semantics as Redis command.

=head2 next

  # blocking
  my $res = $cursor->next();

  # non-blocking
  $cursor->next(sub {
    my ($cur, $err, $res) = @_;
    ...
  })

Issue next C<SCAN> family command with cursor value from previous iteration. If
last argument is coderef, will made a non-blocking call. In blocking mode returns
arrayref with fetched elements. If no more items available, will return
C<undef>, for both blocking and non-blocking, without calling callback.

  my $res = $cursor->next(MATCH => 'namespace*');
  $cursor->next(COUNT => 100, sub { ... });

Accepts the same optional arguments as original Redis command, which will replace
old values and will be used for this and next iterations.

=head2 smembers

  my $list = $redis2->scan->smembers('redis.key');
  $list = $cursor->smembers('redis.key');
  $cursor->smembers('redis.key' => sub {...});

Implements standard C<SMEMBERS> command using C<SSCAN>.

=head1 LINKS

L<http://redis.io/commands>

=cut
