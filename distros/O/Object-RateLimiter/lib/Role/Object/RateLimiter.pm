package Role::Object::RateLimiter;
$Role::Object::RateLimiter::VERSION = '1.004001';
use strictures 2;
use Carp;

use Object::RateLimiter;

use Role::Tiny;

sub delayed {
  my ($self, %args) = @_;
  return $self->{__rl} = Object::RateLimiter->new(%args) if %args;
  confess 
    'Attempted to call ->delayed without a configured ratelimiter',
    ' -- perhaps you wanted ->delayed(events => $x, seconds => $y)'
      unless defined $self->{__rl};
  $self->{__rl}->delay
}

sub clear_delayed {
  my ($self) = @_;
  return unless defined $self->{__rl};
  $self->{__rl}->clear
}

sub get_rate_limiter {
  my ($self) = @_;
  return unless defined $self->{__rl};
  $self->{__rl}
}

1;

=pod

=head1 NAME

Role::Object::RateLimiter - Add a rate limiter to your class

=head1 SYNOPSIS

  package My::Responder;
  use Moo;
  with 'Role::Object::RateLimiter';

  # Set up our rate limiter (any time before attempting to use it):
  has limit_events => (
    is        => 'ro',
    required  => 1,
  );

  has limit_seconds => (
    is        => 'ro',
    required  => 1,
  );

  sub BUILD {
    my ($self) = @_;
    $self->delayed(
      events  => $self->limit_events,
      seconds => $self->limit_seconds
    );
  }

  # do_stuff but only if we're not rate-limited:
  sub respond {
    my ($self) = @_;
    if (my $delay = $self->delayed) {
      sleep $delay
    }
    $self->do_stuff
  }

  sub respond_nonblocking {
    my ($self) = @_;
    return if $self->delayed;
    $self->do_stuff
  }

=head1 DESCRIPTION

This is a small role wrapping L<Object::RateLimiter> to make it slightly more
convenient to add rate limiting to objects.

Currently only C<HASH>-type objects are supported.

Although the L</SYNOPSIS> uses L<Moo>, this role uses L<Role::Tiny> and can
also be composed via L<Role::Tiny::With>.

See L<Object::RateLimiter> for more details.

=head2 delayed

  # Set up the rate limiter:
  $self->delayed(events => 4, seconds => 5);

  # Check if this event should be delayed;
  # returns number of seconds to wait:
  my $delay = $self->delayed;

If called with arguments, passes them to L<Object::RateLimiter>'s constructor
and returns the newly initialized rate limiter; any existing rate limiter is
replaced.

If called without arguments, records an entry in the L<Object::RateLimiter>'s
event history and returns the number of seconds until the event should be
allowed (or zero if not delayed).

See L<Object::RateLimiter/delay>.

=head2 clear_delayed

Clear the current event history.

=head2 get_rate_limiter

Returns the current L<Object::RateLimiter> instance.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
