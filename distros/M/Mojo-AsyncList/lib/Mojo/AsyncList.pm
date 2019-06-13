package Mojo::AsyncList;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop;
use Time::HiRes ();

our $VERSION = '0.02';

has concurrent => 0;
has ioloop     => sub { Mojo::IOLoop->singleton };
has offset     => 1;

sub new {
  my $class     = shift;
  my $item_cb   = ref $_[0] eq 'CODE' ? shift : undef;
  my $finish_cb = ref $_[0] eq 'CODE' ? shift : undef;
  my $self      = $class->SUPER::new(@_);

  $self->on(item   => $item_cb)   if $item_cb;
  $self->on(finish => $finish_cb) if $finish_cb;

  return $self;
}

sub process {
  my ($self, $items) = @_;
  my $remaining = int @$items;
  my ($gather_cb, $item_pos, $pos, @res) = (undef, 0, 0);

  my $stats = $self->{stats}
    = {done => 0, remaining => int(@$items), t0 => [Time::HiRes::gettimeofday]};

  $gather_cb = sub {
    my $res_pos = $pos++;

    return sub {
      shift for 1 .. $self->offset;
      $stats->{done}++;
      $stats->{remaining}--;
      $res[$res_pos] = [@_];
      $self->emit(result => @_);
      return $self->emit(finish => @res) unless $stats->{remaining};
      return $self->emit(item   => $items->[$item_pos++], $gather_cb->())
        if $item_pos < @$items;
    };
  };

  $self->ioloop->next_tick(sub {
    my $n = $self->concurrent;
    $n = @$items if !$n or $n > @$items;
    $self->emit(item => $items->[$item_pos++], $gather_cb->()) for 1 .. $n;
  });

  return $self;
}

sub stats {
  my ($self, $key) = @_;
  return $key ? $self->{stats}{$key} // 0 : $self->{stats};
}

sub wait {
  my $self = shift;
  return if (my $loop = $self->ioloop)->is_running;
  my $done;
  $self->on(finish => sub { $done++; $loop->stop });
  $loop->start until $done;
}

1;

=head1 NAME

Mojo::AsyncList - Process a list with callbacks

=head1 SYNOPSIS

  use Mojo::AsyncList;
  use Mojo::mysql;

  my $mysql = Mojo::mysql->new;
  my $db    = $mysql->db;

  my $async_list = Mojo::AsyncList->new(
    sub { # Specify a "item" event handler
      my ($async_list, $username, $gather_cb) = @_;
      $db->select("users", {username => $username}, $gather_cb);
    },
    sub { # Specify a "finish" event handler
      my $async_list = shift;
      warn $_->[0]{user_id} for @_; # @_ = ([$db_res_supergirl], [$db_res_superman], ...)
    },
  );

  my @users = qw(supergirl superman batman);
  $async_list->concurrent(2);
  $async_list->process(\@users);
  $async_list->wait;

=head1 DESCRIPTION

L<Mojo::AsyncList> is a module that can asynchronously process a list of items
with callback.

=head1 EVENTS

=head2 finish

  $async_list->on(finish => sub { my ($async_list, @all_res) = @_; });

Emitted when L</process> is done with all the C<$items>. C<@all_res> is a list
of array-refs, where each item is C<@res> passed on to L</result>.

=head2 item

  $async_list->on(item => sub { my ($async_list, $item, $gather_cb) = @_; });

Used to process the next C<$item> in C<$items> passed on to L</process>.

=head2 result

  $async_list->on(result => sub { my ($async_list, @res) = @_; });

Emitted when a new result is ready, C<@res> contains the data passed on to
C<$gather_cb>.

=head1 ATTRIBUTES

=head2 concurrent

  $int        = $async_list->concurrent;
  $async_list = $async_list->concurrent(0);

Used to set the number of concurrent items to process. Default value is zero,
which means "process all items" at once.

Used to see how many items that is processing right now.

=head2 offset

  $int        = $async_list->offset;
  $async_list = $async_list->offset(1);

Will remove the number of arguments passed on to <$gather_cb>, used in the
L</item> event. Default to "1", meaning it will remove the invocant.

=head1 METHODS

=head2 new

  $async_list = Mojo::AsyncList->new;
  $async_list = Mojo::AsyncList->new(@attrs);
  $async_list = Mojo::AsyncList->new(\%attrs);
  $async_list = Mojo::AsyncList->new($item_cb, $finish_cb);
  $async_list = Mojo::AsyncList->new($item_cb, $finish_cb, \%attrs);

Used to create a new L<Mojo::AsyncList> object. L</item> and L<finish> event
callbacks can be provided when constructing the object.

=head2 process

  $async_list = $async_list->process(@items);
  $async_list = $async_list->process([@items]);

Process C<$items> and emit L</EVENTS> while doing so.

=head2 stats

  $int          = $async_list->stats("done");
  $int          = $async_list->stats("remaining");
  $gettimeofday = $async_list->stats("t0");
  $hash_ref     = $async_list->stats;

Used to extract stats while items are processing. This can be useful inside the
L</EVENTS>, or within a recurring timer:

  Mojo::IOLoop->recurring(1 => sub {
    warn sprintf "[%s] done: %s\n", time, $async_list->stats("done");
  });

Changing the C<$hash_ref> will have fatal consequences.

=head2 wait

  $async_list->concurrent(2)->process(\@items)->wait;
  $async_list->wait;

Used to block and wait until L<Mojo::AsyncList> is done with the C<$items>
passed on to L</process>.

=head1 AUTHOR

Jan Henning Thorsen

=cut
