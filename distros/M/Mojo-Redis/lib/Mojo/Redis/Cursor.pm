package Mojo::Redis::Cursor;
use Mojo::Base 'Mojo::EventEmitter';

use Carp qw(confess croak);

has connection => sub { shift->redis->_dequeue };
sub command  { $_[0]->{command} }
sub finished { !!$_[0]->{finished} }
has redis => sub { confess 'redis is required in constructor' };

sub again {
  my $self = shift;
  $self->{finished} = 0;
  $self->command->[$self->{cursor_pos_in_command}] = 0;
  return $self;
}

sub all {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift->again;                                                   # Reset cursor
  my $conn = $cb ? $self->connection : $self->redis->_blocking_connection;
  my @res;

  # Blocking
  unless ($cb) {
    my $err;
    while (my $p = $self->_next_p($conn)) {
      $p->then(sub { push @res, @{$_[0] || []} })->catch(sub { $err = shift })->wait;
      croak $err if $err;
    }
    return $self->{process}->($self, \@res);
  }

  # Non-blocking
  my $then;
  $then = sub {
    push @res, @{$_[0]};
    return $self->$cb('', $self->{process}->($self, \@res)) if $self->{finished};
    return $self->_next_p($conn)->then($then);
  };

  $self->_next_p($conn)->then($then)->catch(sub { $self->$cb($_[0], []) });
  return $self;
}

sub all_p {
  my $self = shift->again;        # Reset cursor
  my $conn = $self->connection;
  my ($then, @res);

  $then = sub {
    push @res, @{$_[0]};
    return $self->{process}->($self, \@res) if $self->{finished};
    return $self->_next_p($conn)->then($then);
  };

  return $self->_next_p($conn)->then($then);
}

sub next {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;

  # Cursor is exhausted
  return $cb ? $self->tap($cb, '', undef) : undef
    unless my $p = $self->_next_p($cb ? $self->connection : $self->redis->_blocking_connection);

  # Blocking
  unless ($cb) {
    my ($err, $res);
    $p->then(sub { $res = $self->{process}->($self, shift) })->catch(sub { $err = shift })->wait;
    croak $err if $err;
    return $res;
  }

  # Non-blocking
  $p->then(sub { $self->$cb('', $self->{process}->($self, shift)) })->catch(sub { $self->$cb(shift, undef) });
  return $self;
}

sub next_p {
  my $self = shift;
  return $self->_next_p($self->connection)->then(sub { $self->{process}->($self, shift) });
}

sub new {
  my $self = shift->SUPER::new(@_);
  my $cmd  = $self->command;

  $cmd->[0] ||= 'unknown';
  $self->{process} = __PACKAGE__->can(lc "_process_$cmd->[0]") or confess "Unknown cursor command: @$cmd";

  if ($cmd->[0] eq 'keys') {
    @$cmd = (scan => 0, $cmd->[1] ? (match => $cmd->[1]) : ());
  }
  elsif ($cmd->[0] eq 'smembers') {
    @$cmd = (sscan => $cmd->[1], 0);
  }
  elsif ($cmd->[0] =~ /^(hgetall|hkeys)/) {
    @$cmd = (hscan => $cmd->[1], 0);
  }

  $self->{cursor_pos_in_command} = $cmd->[0] =~ /^scan$/i ? 1 : 2;
  return $self;
}

sub _next_p {
  my ($self, $conn) = @_;
  return undef if $self->{finished};

  my $cmd = $self->command;
  return $conn->write_p(@$cmd)->then(sub {
    my $res = shift;
    $cmd->[$self->{cursor_pos_in_command}] = $res->[0] // 0;
    $self->{finished} = 1 unless $res->[0];
    return $res->[1];
  });
}

sub _process_hgetall  { +{@{$_[1]}} }
sub _process_hkeys    { my %h = @{$_[1]}; return [keys %h]; }
sub _process_hscan    { $_[1] }
sub _process_keys     { $_[1] }
sub _process_scan     { $_[1] }
sub _process_smembers { $_[1] }
sub _process_sscan    { $_[1] }
sub _process_zscan    { $_[1] }

sub DESTROY {
  my $self = shift;
  return unless (my $redis = $self->{redis}) && (my $conn = $self->{connection});
  $redis->_enqueue($conn);
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis::Cursor - Iterate the results from SCAN, SSCAN, HSCAN and ZSCAN

=head1 SYNOPSIS

  use Mojo::Redis;
  my $redis  = Mojo::Redis->new;
  my $cursor = $redis->cursor(hkeys => 'redis:scan_test:hash');
  my $keys   = $cursor->all;

=head1 DESCRIPTION

L<Mojo::Redis::Cursor> provides methods for iterating over the result from
the Redis commands SCAN, SSCAN, HSCAN and ZSCAN.

See L<https://redis.io/commands/scan> for more information.

=head1 ATTRIBUTES

=head2 command

  $array_ref = $cursor->command;

The current command used to get data from Redis. This need to be set in the
constructor, but reading it out might not reflect the value put in. Examples:

  $r->new(command => [hgetall => "foo*"]);
  # $r->command == [hscan => "foo*", 0]

  $r->new(command => [SSCAN => "foo*"])
  # $r->command == [SSCAN => "foo*", 0]

Also, calling L</next> will change the value of L</command>. Example:

  $r->new(command => ["keys"]);
  # $r->command == [scan => 0]
  $r->next;
  # $r->command == [scan => 42]

=head2 connection

  $conn   = $cursor->connection;
  $cursor = $cursor->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis::Connection> object.

=head2 finished

  $bool = $cursor->finished;

True after calling L</all> or if L</next> has iterated the whole list of members.

=head2 redis

  $conn   = $cursor->connection;
  $cursor = $cursor->connection(Mojo::Redis::Connection->new);

Holds a L<Mojo::Redis> object used to create the connections to talk with Redis.

=head1 METHODS

=head2 again

  $cursor->again;

Used to reset the cursor and make L</next> start over.

=head2 all

  $res    = $cursor->all;
  $cursor = $cursor->all(sub { my ($cursor, $res) = @_ });

Used to return all members. C<$res> is an array ref of strings, except when
using the command "hgetall".

=head2 all_p

  $promise = $cursor->all_p->then(sub { my $res = shift });

Same as L</all> but returns a L<Mojo::Promise>.

=head2 new

  $cursor = Mojo::Redis::Cursor->new(command => [...], redis => Mojo::Redis->new);

Used to construct a new object. L</command> and L</redis> is required as input.

Here are some examples of the differnet commands that are supported:

  # Custom cursor commands
  $cursor = $cursor->cursor(hscan => 0, match => '*', count => 100);
  $cursor = $cursor->cursor(scan  => 0, match => '*', count => 100);
  $cursor = $cursor->cursor(sscan => 0, match => '*', count => 100);
  $cursor = $cursor->cursor(zscan => 0, match => '*', count => 100);

  # Convenient cursor commands
  $cursor = $cursor->cursor(hgetall  => "some:hash:key");
  $cursor = $cursor->cursor(hkeys    => "some:hash:key");
  $cursor = $cursor->cursor(keys     => "some:key:pattern*");
  $cursor = $cursor->cursor(smembers => "some:set:key");

The convenient commands are alternatives to L<Mojo::Redis::Database/hgetall>,
L<Mojo::Redis::Database/hkeys>, L<Mojo::Redis::Database/keys> and
L<Mojo::Redis::Database/smembers>.

=head2 next

  $res    = $cursor->next;
  $cursor = $cursor->next(sub { my ($cursor, $err, $res) = @_ });

Used to return a chunk of members. C<$res> is an array ref of strings, except
when using the command "hgetall". C<$res> will also be C<undef()> when the
cursor is exhausted and L</finished> will be true.

=head2 next_p

  $promise = $cursor->next_p;

Same as L</next> but returns a L<Mojo::Prmoise>.

=head1 SEE ALSO

L<Mojo::Redis>.

=cut
