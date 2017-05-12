package Schedule::RateLimiter;
# $Id: RateLimiter.pm,v 1.1 2003/12/04 23:09:10 wright Exp $

use 5.006;
use strict;
use warnings;
use Time::HiRes;

our $VERSION = 0.01;

return 1;

=head1 NAME

Schedule::RateLimiter - prevent events from happening too quickly.

=head1 SYNOPSIS

  use Schedule::RateLimiter;

  # Don't let this event happen more than 5 times in a 60 second period.
  my $throttle = Schedule::RateLimiter->new ( iterations => 5,
                                      seconds    => 60 );

  # Cycle forever, but not too fast.
  while ( 1 ) {
      $throttle->event();
      &do_something;
  }


=head1 DESCRIPTION

This module provides a way to voluntarily restrict how many times a given
action may take place within a specified time frame.  Such a tool may be useful
if you have written something which periodically polls some public resource and
want to ensure that you do not overburden that resource with too many requests.

Initially, one might think that solving this problem would be as simple as
sleeping for the number of seconds divided by the number of iterations in
between each event.  However, that would only be correct if the event took no
time at all.

If you know exactly how much time each event is going to take then you could
build an even more complicated one-liner such as this:

  sleep( (seconds / iterations) - single_event_time )

This module is intended to address the other cases when the exact run-time of
each event is unknown and variable.  This module will try very hard to allow an
event to happen as many times as possible without exceeding the specified
bounds.

For example, suppose you want to write something that checks an 'incoming'
directory once a minute for files and then does something with those files if
it finds any.  If it takes you two seconds to process those files, then you
want to wait 58 seconds before polling the directory again.  If it takes 30
seconds to process those files, then you only want to wait 30 seconds.  And if
it takes 3 minutes, then you want to poll the directory again immediately as
soon as you are done.

  my $throttle = Schedule::RateLimiter->new ( seconds => 60 );
  &poll_and_process while ( $throttle->event );

=head1 METHODS

=cut

=head2 C< new() >

Creates and returns a new Schedule::RateLimiter object.

The constructor takes up to three parameters:

=over

=item * block (default: true)

This parameter accepts a true or false value to set the default "block"
behavior on future calls to event().  It makes it more convenient to turn
blocking off for an entire object at a time.

=item * iterations (default: 1)

This specifies the number of times an event may take place within the given
time period.  This must be a positive, non-zero integer.

=item * seconds (required)

This specifies the minimum number of seconds that must transpire before we will
allow (iterations + 1) events to happen.  A value of 0 disables throttling.
You may specify fractional time periods.

=back

B<example>:

  my $throttle = Schedule::RateLimiter->new ( iterations => 2,
                                      seconds    => 10 );

  # Event 1
  $throttle->event();
  # Event 2
  $throttle->event();
  # Event 3
  $throttle->event(); 
  # 10 seconds will have transpired since event 1 at this point.
  # Event 4
  $throttle->event(); 
  # 10 seconds will have transpired since event 2 at this point.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = @_;

    die "Missing 'seconds' argument" unless defined( $args{seconds} );

    if ( $args{seconds} =~ /[^-\d\.]/ ) {
        die "'seconds' argument must be numeric";
    }

    my $iterations = $args{iterations} || 1;

    if ( $iterations =~ /[^-\d\.]/ ) {
        die "'iterations' argument must be numeric";
    }

    if ( int($iterations) != $iterations ) {
        die "'iterations' argument must be integer";
    }

    die "'iterations' argument must be positive" if $iterations < 0;

    my @list;
    $#list = $iterations -1;

    bless { 
        current     => 0,
        list        => \@list,
        iterations  => $iterations,
        seconds     => $args{seconds},
        block       => ( exists($args{block}) ) ? $args{block} : 1,
    }, $proto;
}

=head2 C< event() >

Called to signal the beginning of an event.  This method will return true or
false to indicate if it is ok to proceed with the event.  This method uses
Time::HiRes to do its calculations and sleeping, so the precision of this
method will be the same as the precision of Time::HiRes on your platform.

Takes one (optional) parameter:

=over

=item * block (default: true)

If set to a false value, this method will do a non-blocking check to see if it
is ok for the event to occur.  If it is not ok, this method will return a false
value and assume that the event did not take place.  Otherwise, this method
will return a true value and assume that the event did take place.

=back

B<example>:

  # Stop when the code moves too fast.
  while ( 1 ) {
      if ($throttle->event( block => 0 )) {
          &do_something;
      } else {
          die 'I went too fast!';
      }
  }

=cut

sub event {
    my $self = shift;
    my %args = @_;

    my $t = Time::HiRes::time();

    my $last = $self->{list}[$self->{current}] || 0;
    my $block = exists( $args{block} ) ? $args{block} : $self->{block};

    if ( ($t - $last) < $self->{seconds} ) {
        return 0 unless $block;
        Time::HiRes::sleep($self->{seconds} - ($t - $last));
    }

    $self->{list}[$self->{current}] = $t;

    $self->{current} = ($self->{current}+1) % $self->{iterations};

    return 1;
}

=head1 BUGS

This module needs to keep a record of when every iteration took place, so if
you are allowing a large number of iterations to happen in the given time
period, this could potentially use a lot of memory.

=head1 KNOWN ISSUES

If you have multiple iterations that typically happen very quickly, and you
want to limit them in a long period of time, they will "clump" together.  That
is, they all happen at just about the same time, and then the system waits for
a long period before doing the same "clump" again.  That's just the nature of
the best-fit algorithm.  Anything that is done to try to separate single events
with longer waits than necessary will potentially create a sub-optimal
situation if an event in the future takes longer than expected.  If you really
want all of your events to start at even time periods apart from each other,
then set the number of iterations to 1 and adjust the number of seconds
accordingly.

=head1 AUTHOR

Daniel J. Wright, E<lt>wright@pair.comE<gt>

=head1 SEE ALSO

The POE module provides a more heavyweight solution to this problem as well.

L<perl>.

=cut
