package Object::RateLimiter;
$Object::RateLimiter::VERSION = '1.004001';
use strictures 2;

use Carp 'confess';
use List::Objects::WithUtils 'array';
use Scalar::Util 'blessed';
use Time::HiRes  'time';

use namespace::clean;

use overload
  '&{}'    => sub {
    my $self = shift;
    sub { $self->delay }
  },
  fallback => 1;

use Object::ArrayType::New
  [ events  => '', seconds => 'SECS', _queue => 'QUEUE' ];
sub seconds  { $_[0]->[SECS]   }
sub events   { $_[0]->[EVENTS] }
sub _queue   { $_[0]->[QUEUE]  }

use Class::Method::Modifiers;
around new => sub {
  my ($orig, $class) = splice @_, 0, 2;
  my $self = $class->$orig(@_);
  confess "Constructor requires 'seconds =>' and 'events =>' parameters"
    unless defined $self->seconds and defined $self->events;
  $self->[QUEUE] = array(@{ $self->_queue })
    if $self->_queue and ref $self->_queue eq 'ARRAY';
  $self
};

sub clone {
  my ($self, %params) = @_;
  $params{events}  = $self->events  unless defined $params{events};
  $params{seconds} = $self->seconds unless defined $params{seconds};
  $params{_queue}  = $self->_queue->copy if $self->_queue;
  $self->new(%params);
}

{ no warnings 'once'; *TO_JSON = *export }
sub export {
  my ($self) = @_;
  +{
    events   => $self->events, 
    seconds  => $self->seconds, 
    _queue   => $self->_queue->unbless,
  }
}

sub delay {
  my ($self) = @_;
  my $thisq  = $self->[QUEUE] ||= array;
  my $ev_limit = $self->events;

  if ((my $ev_count = $thisq->count) >= $ev_limit) {
    my $oldest_ts = $thisq->get(0);

    my $delayed = ( 
      $oldest_ts 
      + ( $ev_count * $self->seconds / $ev_limit ) 
    ) - time;

    $delayed > 0 ? return($delayed) : $thisq->shift
  }

  $thisq->push( time );

  0
}


sub clear { $_[0]->[QUEUE] = undef; 1 }

sub expire {
  my ($self) = @_;
  return unless $self->is_expired;
  $self->clear
}

sub is_expired {
  my ($self) = @_;
  my $thisq  = $self->_queue   || return;
  my $latest = $thisq->get(-1) || return;

  time - $latest > $self->seconds
}

print
  qq[<Gilded> Every girlfriendless introvert is now on a list\n],
  qq[<c[_]> already was^\n],
  qq[<Gilded> Well yeah the World of Warcraft subscriber database],
  qq[ but I meant like a government thing\n]
unless caller; 1;

=pod

=for Pod::Coverage EVENTS QUEUE SECS TO_JSON

=head1 NAME

Object::RateLimiter - A flood control (rate limiter) object

=head1 SYNOPSIS

  use Object::RateLimiter;

  my $ctrl = Object::RateLimiter->new(
    events  => 3,
    seconds => 5
  );

  # Run some subs, as a contrived example;
  # no more than 3 in 5 seconds, per our constructor above:
  my @work = (
    sub { "foo" },  sub { "bar" },
    sub { "baz" },  sub { "cake" },
    # ...
  );

  while (my $some_item = shift @work) {
    if (my $delay = $ctrl->delay) {
      # Delayed $delay (fractional) seconds.
      # (You might want Time::HiRes::sleep, or yield to event loop, etc)
      sleep $delay
    }
    print $some_item->()
  }

  # Clear the event history if it's stale:
  $ctrl->expire;

  # Clear the event history unconditionally:
  $ctrl->clear;

  # Same as calling ->delay:
  my $delayed = $ctrl->();

=head1 DESCRIPTION

This is a generic rate-limiter object, implementing the math described in
L<http://www.perl.com/pub/2004/11/11/floodcontrol.html> via light-weight
array-type objects.

The algorithm is fairly simple; the article linked above contains an in-depth
discussion by Vladi Belperchinov-Shabanski (CPAN:
L<http://www.metacpan.org/author/CADE>):

  $delay =
    ( 
      $oldest_timestamp + 
      ( $seen_events * $limit_secs / $event_limit ) 
    )
    - time()

This module uses L<Time::HiRes> to provide support for fractional seconds.

See L<Algorithm::FloodControl> for a similar module with a functional
interface & persistent on-disk storage features (for use with CGI
applications).

=head2 new

  my $ctrl = Object::RateLimiter->new(
    events  => 3,
    seconds => 5
  );

Constructs a new rate-limiter with a clean event history.

Accepts params as a list or a single HASH.

=head2 clear

  $ctrl->clear;

Clear the event history.

=head2 clone

  my $new_ctrl = $ctrl->clone( events => 4 );

Clones an existing rate-limiter; new options can be provided, overriding
previous settings. 

The new limiter contains a clone of the event history; the old rate-limiter is
left untouched.

=head2 delay

  if (my $delay = $ctrl->delay) {
    sleep $delay;  # ... or do something else
  } else {
    # Not delayed.
    do_work;
  }

  # Same as calling ->delay:
  my $delay = $ctrl->();

The C<delay()> method determines if some work can be done now, or should wait.

When called, event timestamps are considered; if we have exceeded our limit,
the delay in (possibly fractional) seconds until the event would be
allowed is returned.

A return value of 0 indicates that the event does not need to wait.

=head2 events

Returns the B<events> limit the object was constructed with.

=head2 expire

  $ctrl->expire;

Clears the event history if L</is_expired> is true.

Returns true if L</clear> was called.

(You're not required to call C<expire()>, but it can be useful to save a
little memory.)

=head2 export

  my $opts = $ctrl->export;
  # ... later, perhaps after storing/retrieving ...
  my $recreated = Object::RateLimiter->new($opts);

Exports the current state of the rate-limiter as a reference to a hash; the
exported hash can be fed to L</new> to recreate the rate-limiter.

This is useful if the rate-limiter's state must be stored persistently. 

=head2 is_expired

Returns true if the last seen event is outside of our time window (in other
words, the event history is stale) or there is no event history.

Also see L</expire>

=head2 seconds

Returns the B<seconds> limit the object was constructed with.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Based on the math from L<Algorithm::FloodControl> as described in an article
written by the author:
L<http://www.perl.com/pub/2004/11/11/floodcontrol.html>

Licensed under the same terms as Perl.

=cut
