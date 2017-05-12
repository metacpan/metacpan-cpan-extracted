#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Period.pm,v 1.19 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Period -- represent a period of time

=cut

package Net::ICal::Period;
use strict;

use UNIVERSAL;
use base qw(Net::ICal::Property);

use Data::Dumper;
use Net::ICal::Duration;
use Net::ICal::Time;

=head1 SYNOPSIS

  use Net::ICal;
  $p = new Net::ICal::Period("19970101T120000","19970101T123000");
  $p = new Net::ICal::Period("19970101T120000","PT3W2D40S");
  $p = new Net::ICal::Period(time(),3600);
  $p =   new Net::ICal::Period(
		      new Net::ICal::Time("19970101T120000",
					  "America/Los_Angeles"),
		      new Net::ICal::Duration("2h"));

=head1 DESCRIPTION

Use this to make an object representing a block of time on a
real schedule. You can either say, "This event starts at 12
and ends at 2" or "This event starts at 12 and lasts 2 hours."

These two ways of specifying events can be treated differently
in schedules. If you say, "The meeting is from 12 to 2, but I 
have to leave at 2," you are implying that the start date and
end date are fixed. If you say, "I have a 2-hour drive to
Chicago, and I need to leave at 4," you are saying that it will
take 2 hours no matter when you leave, and that moving the start
time will slide the end time correspondingly. 

=head1 BASIC METHODS

=head2 new($time, $time|$duration)

Creates a new period object given to parameters: The first must be a
I<Time> object or valid argument to Net::ICal::Time::new.

The second can be either: 

=over 4

=item * a I<Time> object

=item * a valid argument to Net::ICal::Time::new. 

=item * a I<Duration> object

=item * a valid argument to Net::ICal::Duration::new. 

=back 

Either give a start time and an end time, or a start time and a duration.

=cut


#-------------------------------------------------------------------------

=head2 new($time, $time|$duration)

Creates a new period object given to parameters: The first must be a
I<Time> object or valid argument to Net::ICal::Time::new.

The second can be either: 

=over 4

=item * a I<Time> object

=item * a valid argument to Net::ICal::Time::new. 

=item * a I<Duration> object

=item * a valid argument to Net::ICal::Duration::new. 

=back 

Either give a start time and an end time, or a start time and a duration.

=begin testing


use Net::ICal::Period;

my $p = Net::ICal::Period->new();  # should FAIL

ok(!defined($p), "new() with no args fails properly");

my $begin = "19890324T123000Z";
my $end = '19890324T163000Z';
my $durstring = 'PT4H';

$p = Net::ICal::Period->new(
    Net::ICal::Time->new(ical => $begin),
    Net::ICal::Time->new(ical => $end)
    );

ok(defined($p), "new() with 2 time objects as args succeeds");

# TODO: new() tests with all the argument types listed in the
# docs. I'm *sure* some of them don't work, because the API
# for Time and Duration has changed since that POD was written. -srl

ok($p->as_ical eq "$begin/$end", "ical output is correct");


$p = Net::ICal::Period->new($begin, $end);

ok(defined($p), "new() with 2 time strings as args succeeds");

# TODO: new() tests with all the argument types listed in the
# docs. I'm *sure* some of them don't work, because the API
# for Time and Duration has changed since that POD was written. -srl

ok($p->as_ical eq "$begin/$end", "ical output is correct for dtstart/dtend");


$p = Net::ICal::Period->new($begin, $durstring);

ok(defined($p), "new() with timestring and durstring as args succeeds");

# TODO: new() tests with all the argument types listed in the
# docs. I'm *sure* some of them don't work, because the API
# for Time and Duration has changed since that POD was written. -srl

print $p->as_ical . "\n";

ok($p->as_ical eq "$begin/$durstring", "ical output is correct for dtstart/duration strings");


=end testing

=cut

sub new{
  my ($package, $arg1, $arg2) = @_;
  
  return undef unless (defined($arg1) && defined($arg2) );
  
  my $self = {};

  # Is the string in RFC2445 Format?
  if(!$arg2 and $arg1 =~ /\//){
    my $tmp = $arg1;
    ($arg1,$arg2) = split(/\//,$tmp);
  }


  if( ref($arg1) eq 'Net::ICal::Time'){
    $self->{START} = $arg1->clone();
  } else  {
    $self->{START} = new Net::ICal::Time(ical => $arg1);
  } 
    

  if(UNIVERSAL::isa($arg2,'Net::ICal::Time')){ 
    $self->{END} = $arg2->clone();
  } elsif (UNIVERSAL::isa($arg2,'Net::ICal::Duration')) {
    $self->{DURATION} = $arg2->clone();
  } elsif ($arg2 =~ /^P/) {
    $self->{DURATION} = new Net::ICal::Duration($arg2);
  } else {
    # Hope that it is a time string
    $self->{END} = new Net::ICal::Time(ical => $arg2);
  }

  return bless($self,$package);
}

#--------------------------------------------------------------------------
=pod
=head2 clone()

Create a copy of this component

=begin testing

ok($p->clone() ne "Not implemented", "clone method is implemented");

$q = $p->clone();
ok(defined($q) , "clone method creates a defined object");

SKIP: {
    skip "This test makes the tests crash utterly", 1 unless 0;
    ok($p->as_ical eq $q->as_ical , "clone method creates an exact copy");
};

=end testing

=cut

sub clone {
    my $self = shift;

    my $class = ref($self);
    return bless( {%$self}, $class );

}

#----------------------------------------------------------------------------

=head2 is_valid()

Return true if:
  There is an end time and:
     Both start and end times have no timezone ( Floating time) or
     Both start and end time have (possibly different) timezones or
     Both start and end times are in UTC and
     The end time is after the start time. 

  There is a duration and the duration is positive  

=begin testing

ok($p->is_valid() ne "Not implemented", "is_valid method is implemented");

=end testing

=cut

# XXX implement this

sub is_valid {
    return "Not implemented";
}

#---------------------------------------------------------------------------
=pod
=head2 start([$time])

Accessor for the start time of the event as a I<Time> object.
Can also take a valid time string or an integer (number of
seconds since the epoch) as a parameter. If a second parameter
is given, it'll set this Duration's start time. 

=begin testing

# TODO: write tests
ok(0, 'start accessor tests exist');

=end testing

=cut

sub start{
  my $self = shift;
  my $t = shift;

  if($t){
    if(UNIVERSAL::isa($t,'Net::ICal::Time')){ 
      $self->{START} = $t->clone();
    } else {
      $self->{START} = new Net::ICal::Time($t);
    }
  }

  return $self->{START};
} 

#-----------------------------------------------------------------
=pod
=head2 end([$time])

Accessor for the end time. Takes a I<Time> object, a valid time string,
or an integer and returns a time object. This routine is coupled to 
the I<duration> accessor. See I<duration> below for more imformation. 

=begin testing

# TODO: write tests
ok(0, 'end accessor tests exist');

=end testing

=cut

sub end{

  my $self = shift;
  my $t = shift;
  my $end;

  if($t){
    if(UNIVERSAL::isa($t,'Net::ICal::Time')){
      $end = $t->clone();
    } else {
      $end = new Net::ICal::Time($t);
    }
    
    # If duration exists, use the time to compute a new duration
    if ($self->{DURATION}){
      $self->{DURATION} = $end->subtract($self->{START}); 
    } else {
      $self->{END} = $end;
    }    
  }

  # Return end time, possibly computing it from DURATION
  if($self->{DURATION}){
    return $self->{START}->add($self->{DURATION});
  } else {
    return $self->{END};
  }

} 

#----------------------------------------------------------------------
=pod
=head2 duration([$duration])

Accessor for the duration of the event. Takes a I<duration> object and
returns a I<Duration> object. 

Since the end time and the duration both specify the end time, the
object will store one and access to the other will be computed. So,

if you create:

   $p = new Net::ICal::Period("19970101T120000","19970101T123000")

And then execute:

   $p->duration(45*60);

The period object will adjust the end time to be 45 minutes after
the start time. It will not replace the end time with a
duration. This is required so that a CUA can take an incoming
component from a server, modify it, and send it back out in the same
basic form.

=begin testing

# TODO: write tests
TODO: {
    local $TODO = "write duration accessor tests";
    ok(0, 'duration accessor tests exist');

}
=end testing

=cut

sub duration{
  my $self = shift;
  my $d = shift;
  my $dur;

  if($d){
    if(UNIVERSAL::isa($d,'Net::ICal::Duration')){ 
      $dur = $d->clone();
    } else {
      $dur = new Net::ICal::Duration($d);
    }
    
    # If end exists, use the duration to compute a new end
    # otherwise, set the duration. 
    if ($self->{END}){
      $self->{END} = $self->{START}->add($dur); 
    } else {
      $self->{DURATION} = $dur;
    }    
  }

  # Return duration, possibly computing it from END
  if($self->{END}){
    return $self->{END}->subtract($self->{START});
  } else {
    return $self->{DURATION};
  }

}

#------------------------------------------------------------------------

=head2 as_ical()

Return a string that holds the RFC2445 text form of this period 

=begin testing

TODO: {
    local $TODO = 'write tests for N::I::Period as_ical';
    ok(0, "as_ical tests exist");
}

=end testing

=cut

sub as_ical {
  my $self = shift;
  my $out;

  my $colon_clipped_date = $self->{START}->as_ical_value();
  $out = $colon_clipped_date ."/";

  if($self->{DURATION}){
    $out .= $self->{DURATION}->as_ical_value(); 
  } else {
    $colon_clipped_date = $self->{END}->as_ical_value();
    $out .= $colon_clipped_date;
  }
 
  return $out;
 
}

=pod 

=head2 as_ical_value

Another name for as_ical.

=begin testing

# TODO: write tests
ok(0, "as_ical_value tests exist");

=end testing

=cut

sub as_ical_value {
  my $self = shift;

  return $self->as_ical();
}



=pod

=head2 compare([$time])

Takes a Net::ICal::Time as a parameter.
If the parameter is a Time, returns 0 if I<time> is in the period, 
-1 if the time is before the period and 1 if the time is after the period.

=begin testing

# TODO: write tests
ok(0, "compare tests exist");

=end testing

=cut

sub compare {
    my ($self, $t) = @_;
    my $time;

    if($t){
        
        if(UNIVERSAL::isa($t,'Net::ICal::Time')){
            $time = $t->clone();
        } else {
            $time = new Net::ICal::Time(ical => $t);
        }
        
        # If the time is before the start of the duration
        if($self->start->compare($time) < 0) {
            return -1;
        }
        # If the time is after the end of the duration
        if($self->end->compare($time) >= 0) {
            return 1;
        }

        return 0;
    }

  return undef;
}




=pod

=head2 union([$period])

Takes another Period as a parameter. Returns 0 if the given I<period> overlaps 
this period, -1 if the given Period is before this one,  and 1 if the given Period
is after this one.

=begin testing

# TODO: write tests
ok(0, "union tests exist");

=end testing

=cut

# XXX: Perhaps this should return a Period if the two periods overlap.
# Or maybe that's a separate function.
sub union {

  my ($self, $period2) = @_;

  # does $period2 overlap with this period?
  if($period2){

    # If the start of the parameter period is after this period:
    if($self->end->compare($period2->start) >= 0) {
      return 1;
    }
    # If the end of this period is before the end of the parameter period
    if($self->start->compare($period2->end) <= 0) {
      return -1;
    }
    return 0;
  }

  return undef;
}

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
