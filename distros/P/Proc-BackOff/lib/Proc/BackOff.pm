package Proc::BackOff;

# Inheritance
use base qw( Class::Accessor );

# Set up get/set fields
__PACKAGE__->mk_accessors( 'max_timeout',
                           'failure_count',          # current failure count
                           'failure_start',          # time that inital failure
                                                     # - started.  Recorded for
                                                     # - future classes
                           'failure_time',           # time of last failure
                           'failure_over',           # when will the failure be over?
                           'backOff_in_progress',    # back off is in progress.
                           'init',                   # was this initalized?
);

# standard pragmas
use warnings;
use strict;

# standard perl modules

# CPAN & others

our $VERSION = '0.02';

=head1 NAME

Proc::BackOff

=head1 SYNOPSIS

Usage:

 use Proc::BackOff::Linear;

 my $obj = Proc::BackOff::Linear->new( { slope => 5 } );

 while ( 1 ) {
     # delay will return
     #      0 : No delay needed.
     #      N : or the number of seconds until back off is completed.

     sleep $obj->delay() if $obj->delay();
  	 # or
  	 $obj->sleep();

     if ( do_attempt() ) {
         # success
         $obj->success(); # passing success to Proc::BackOff will reset
                          # Proc::BackOff
     } else {
         # failure
         $obj->failure(); # passing failure will instruct Proc::BackOff to
                          # increment the time to back off
     }

     # 100 failures in a row, time to exit
     die "complete failure" if $obj->failure_count() > 100;
 }

 $obj->reset(); # reset back the same state as it was new.

=head1 DESCRIPTION

Proc::BackOff is a base module meant to be directly inherited from and then
modified by overloading the calculate_back_off object method.

Use: Proc::BackOff::Linear, Proc::BackOff::Random, or Proc::BackOff::Exponential.

Any success C<$obj-E<gt>success()> will result, in the back off being removed.

=head1 METHODS

=head2 new()

This is for internal use only.

Do not call this function, call new from:
L<Proc::BackOff::Linear>,
L<Proc::BackOff::Random>, or L<Proc::BackOff::Exponential>.

=cut

sub new {
    my ( $proto, $fields ) = @_;

    my $class = ref $proto || $proto;

    $fields = {} unless defined $fields;

    # make a copy of $fields.
    my $obj = bless {%$fields}, $class;

    # reset uses max_timeout, so max_timeout must be set first.
    $obj->max_timeout(0) unless defined $obj->max_timeout();

    $obj->reset();

    return $obj;
}

=head2 delay()

Delay will return the following

    > 0, number of seconds until the delay is over
    0 delay is up.  Meaning that you should do your next attempt.

=cut

sub delay {
    my $self = shift;

    return 0 if $self->failure_time() == 0;
    return 0 if $self->backOff_in_progress() == 0;

    #              current time   -    end of timeout
    my $time = time; # to help with debugging
    my $timeLeft = $self->failure_over() - $time;

    # $timeLeft < 0  we are done
    # $timeLeft = 0  we are done
    # $timeLeft > 0  we have time remaining

    return $timeLeft > 0 ? $timeLeft : 0;
}

=head2 sleep()

This is a short cut for:

    sleep $obj->delay() if $obj->delay();

=cut

sub sleep {
    my $self = shift;

    sleep $self->delay() if $self->delay();
}


=head2 success()

Success will clear Proc::BackOff delay.

=cut

sub success {
    my $self = shift;

    $self->reset();
}

=head2 reset()

Simply just resets $obj back to a state in which no "backing off" exists.

=cut

sub reset {
    my $self = shift;

    $self->failure_count(0);
    $self->failure_over(0);
    $self->failure_time(0);
    $self->failure_start(0);
    $self->backOff_in_progress(0);
}

=head2 failure()

Failure will indicicate to the object to increment the current BackOff time.

The calculate_back_off function is called to get the time in seconds to wait.

The time waited is time+calculated_back_off time, however it is capped by
$self->max_timeout().

=cut

sub failure {
    my $self = shift;

    $self->backOff_in_progress(1);
    $self->failure_count( $self->failure_count() + 1 );

    my $time = time;
    $self->failure_start($time) if $self->failure_start() == 0;
    $self->failure_time($time);

    my $moreTime = $self->calculate_back_off();

    # if   - max_timeout > 0, then we cap timeout at max_timeout
    $moreTime = $self->max_timeout()
        if ( $self->max_timeout() > 0 && $moreTime > $self->max_timeout() );
    # else - To infinity and beyond! -Buzz Lightyear

    $self->failure_over($time+$moreTime);
}

=head2 valid_number_check()

Is this a number we can use?

1
1.234
'count'

are valid values.

=cut

sub valid_number_check {
    my $self = shift;
    return undef unless defined $_[0];

    # Regex from: http://p3m.org/faq/C3/Q3.html
    return $_[0] =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ || $_[0] eq 'count';
}


=head2 calculate_back_off()

Returns the new back off value.

This is the key function you want to overload if you wish to create your own
BackOff library.

The following functions can be used.

=over 4

=item * $self->failure_count()

The current number of times, that failure has been sequentially called.

=item * $self->failure_start()

When as reported by time in seconds from epoch was failure first called

=item * $self->failure_time()

When was the last failure reported ie, $self->failure() called.

=item * $self->failure_over()

When in time since epoch will the failure be over.

=back

=cut

sub calculate_back_off {
    die "Virtual Method";
}

# subroutines automatically created by mk_accessors
# Class

=head2 backOff_in_progress()

returns 1 if a back off is in progress

returns 0 if a back off is not in progress.

The difference between backOff_in_progress and delay() > 0, is that at the end
of a timeout, delay() will return 0, while the backoff will still be in
progress.

=head2 max_timeout()

Subroutine automatically created by mk_accessors.

Get $obj->max_timeout()

Set $obj->max_timeout( 60*60 ) ; # 60 * 60 seconds = 1 hour

The Maximum amount of time to wait.

A max_timeout value of zero, means there is no Maximum.

=head2 failure_time()

Subroutine automatically created by mk_accessors.

When was $obj->failure() last called?  Time in seconds since epoch.

Get $obj->failure_time()

This variable is not meant to be set by the end user.  This variable is set when
$obj->failure() is called.

=head2 failure_over()

When in seconds since epoch is the failure_over()?

This is used internally by object method delay();

=cut

1;

=head1 Inheritance

I have included an exponential, linear, and random back off.  You can use any of
these sub classes to make a new back off library.  Please consider sending me
any additional BackOff functions, so that I may include it for others to use.

=head1 Notes

Please send me any bugfixes or corrections.  Even spelling correctins :).

Please file any bugs with:

 L<http://rt.cpan.org/Public/Dist/Display.html?Name=Proc-BackOff>

=head1 Changes

 0.02   2007-08-12 -- Daniel Lo
        - Documentation fixes.  No code changes.

 0.01   2007-04-17 -- Daniel Lo
        - Initial version

=head1 AUTHOR

Daniel Lo <daniel_lo@picturetrail.com>

=head1 LICENSE

Copyright (C) PictureTrail Inc. 1999-2007
Santa Clara, California, United States of America.

This code is released to the public for public use under Perl's Artisitic
licence.

=cut
