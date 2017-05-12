#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the same terms as perl itself. ( Either the Artistic License or the
# GPL. ) 
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list. 
#======================================================================

=pod

=head1 NAME

Net::ICal::Time -- represent a time and date

=head1 SYNOPSIS

    $t = Net::ICal::Time->new( epoch => time );
    $t = Net::ICal::Time->new( ical => '19970101' );
    $t = Net::ICal::Time->new( ical => '19970101T120000',
        timezone => 'America/Los_Angeles' );

    # Eventually ...
    $t = Net::ICal::Time-new( iso => '1997-10-14' );
    # or other time formats ...

    # Not yet implemented
    $t = Net::ICal::Time->new(
        second => 12,
        minute => 5,
        hour => 6,
        day => 10,
        month => 9,
        year => 1997,
    );

    # Not yet implemented
    $t2 = $t->add( hour => '6' );
    
=head1 WARNING

This is ALPHA QUALITY CODE. Due to a roundoff error in
Date::ICal, which it's based on, addition and subtraction is
often one second off. Patches welcome. See the README that
came with this module for how you can help.

=head1 DESCRIPTION

I<Time> represents a time, but can also hold the time zone for the
time and indicate if the time should be treated as a date. The time
can be constructed from a variey of formats.

=head1 METHODS

=cut

package Net::ICal::Time;
use strict;

use base qw(Date::ICal);

use Net::ICal::Duration;
use Time::Local;
use POSIX;
use Carp qw(confess cluck);
use UNIVERSAL;

=pod

=head2 new

Creates a new time object given one of:

=over 4

=item * epoch => integer seconds past the POSIX epoch.

=item * ical => iCalendar date-time string

=back

If neither of these arguments is supplied, the value will default to
the current date. 

WARNING: Timezone handling is currently in flux in Net::ICal, pending
Date::ICal awareness of timezones. This may change the call syntax slightly.

=begin testing
use lib "../lib";

use Net::ICal::Time;
my $t1 = new Net::ICal::Time(ical => '20010402');

ok(defined($t1), 'simple iCal creation test (date only)');

print $t1->as_ical . "\n";

# note: there *should* be a Z on the end of the string, because we assume
# that new dates are in UTC unless otherwise specified.
ok($t1->as_ical eq ':20010402Z', 'simple iCal creation (date only) makes correct iCal');

# TODO: define more tests in this vein that are Net::ICal specific.
# Mostly, you want the tests here to be Date::ICal tests; 
# Don't just add tests here unless they test something specific to N::I.

=end testing



=head2 clone()

Create a new copy of this time. 

=begin testing

$t1 = new Net::ICal::Time(epoch => '22');
my $t2 = $t1->clone();

# FIXME: This test is weak because it relies on compare() working
ok($t1->compare($t2) == 0, "Clone comparison says they're the same");

=end testing

=cut

# clone a Time object. 
sub clone {
  my $self = shift;

  return bless( {%$self},ref($self));

}


=pod

=head2 zone

Accessor to the timezone. Takes & Returns an Olsen place name
("America/Los_Angeles", etc. ) , an Abbreviation, 'UTC', or 'float' if
no zone was specified.

THIS IS NOT YET IMPLEMENTED. Date::ICal does not yet support timezones.

=begin testing

#XXX: commented because todo tests aren't implemented yet in Test::More
#todo { ok (1==1, 'timezone testing') } 1, "no timezone support yet";

=end testing

=cut

# XXX This needs to be defined. 
sub zone {}

=pod

=head2 add($duration)

Takes a duration string or I<Duration> and returns a 
I<Time> that is the sum of the time and the duration. 
Does not modify this time.

=begin testing

$t1 = Net::ICal::Time->new( ical => '20010405T160000Z');
my $d1 = Net::ICal::Duration->new ('PT15M');
print $d1->as_ical_value() . "\n";

$t1->add($d1->as_ical_value);

print $t1->ical . "\n";
ok($t1->ical eq "20010405T161500Z", "adding minutes from an iCal string works");

#---------------------------------------------------
$t1 = Net::ICal::Time->new( ical => '20010405T160000Z');
$t1->add($d1);

print $t1->ical . "\n";
ok($t1->ical eq "20010405T161500Z", "adding minutes from a Duration object works");

# NOTE: Most tests of whether the arithmetic actually works should
# be in the Date::ICal inline tests. These tests just make sure that
# N::I::Time is wrappering D::I sanely.

=end testing

=cut
sub add {
  my ($self, $param) = @_;
  
  # FIXME: need input validation here
  my $duration = $param;
  
  # be backwards-compatible for now. 
  if (UNIVERSAL::isa($param,'Net::ICal::Duration')) {
    #probably the Wrong Way, but it works for now. 
    $duration = $param->as_ical_value;   
  };

  # at this point, assume that duration is an iCalendar string.
  return $self->SUPER::add(duration=>$duration);

}

=pod

=head2 subtract($time)

Subtract out a time of type I<Time> and return a I<Duration>. Does not
modify this time.

=begin testing

$t1 = Net::ICal::Time->new( ical => '20010405T160000Z');
$d1 = Net::ICal::Duration->new('PT15M');

print $d1->as_ical_value . "\n";
$t1->subtract($d1->as_ical_value);
print "result was " . $t1->as_ical_value . "\n";
ok($t1->as_ical_value eq "20010405T154500Z", "subtracting minutes using an iCal string works");

#---------------------------------------------------
$t1 = Net::ICal::Time->new( ical => '20010405T160000Z');
$t1->subtract($d1);

print $t1->as_ical_value . "\n";

ok($t1->as_ical_value eq "20010405T154500Z", "subtracting minutes using a Duration object works");

# NOTE: Most tests of whether the arithmetic actually works should
# be in the Date::ICal inline tests. These tests just make sure that
# N::I::Time is wrappering D::I sanely.

=end testing

=cut
sub subtract {
  my $self = shift;
  my $param = shift;

  my $duration = $param;
  
  # be backwards-compatible for now. 
  if (UNIVERSAL::isa($param,'Net::ICal::Duration')) {
    # probably the Wrong Way, but it works for now. 
    $duration = $param->as_ical_value();   
  };

  $duration = "-" . $duration;  # negate the duration they gave, so we can subtract

  return $self->add($duration);

}

=pod

=head2 move_to_zone($zone);

Change the time to what it would be in the named timezone. 
The zone can be an Olsen placename or "UTC". 

THIS FUNCTION IS NOT YET IMPLEMENTED. We're waiting on Date::ICal
to provide this function.

=begin testing
TODO: {
    local $TODO = "implement move_to_zone";
    ok(0, "move_to_zone isn't implemented yet");

};
=end testing

=cut

# XXX this needs implementing, possibly by Date::ICal. 
sub move_to_zone {
  confess "Not Implemented\n";
} 


=pod

=head2 as_ical()

Convert to an iCal format property string.

=begin testing
#TODO
=end testing


=cut
sub as_ical {
  my $self = shift;
  
  # fallback to Date::ICal here
  return ":" . $self->ical; 
}

sub as_ical_value {
    my ($self) = @_;
    return $self->ical;
}

=pod

=head2 as_localtime()

Convert to list format, as per localtime(). This is *not* timezone safe. 

=for testing
#TODO

=cut
sub as_localtime {
  my $self = shift;

  return localtime($self->epoch());

}

=pod

=head2 as_gmtime()

Convert to list format, as per gmtime()

=for testing
#TODO

=cut
sub as_gmtime {
  my $self = shift;

  return gmtime($self->epoch());

}

=pod

=head2 day_of_week()

Return 0-6 representing day of week of this date.

=for testing
#TODO

=cut
# XXX Implement this
sub day_of_week {
  my $self = shift;

  return (gmtime($self->epoch()))[6];
}

=pod

=head2 day_of_year()

Return 1-365 representing day of year of this date. 

=for testing
#TODO

=cut

# XXX Implement this
sub day_of_year {
  my $self = shift;

  return (gmtime($self->epoch()))[7];
}


=pod

=head2 start_of_week()

Return the day of year of the first day (Sunday) of the week that
this date is in

=for testing
#TODO

=cut

# XXX Implement this
sub start_of_week {
  my $self = shift;

  # There's an issue here when Sunday is in the previous year. Should we return
  # the day number in the previous year? But then the calling program has to
  # be smart enough to notice this, Ive chosen here to return a negative year
  # day to indicate last year (okay Im lazy means I don't have to worry about
  # leap years). Note that it seems that localtime etc count days from 0..364
  # rather than 1..365 as it states in the man pages, am I missing something??
  # Sunday is zero hence the need to subtract an extra day
  return $self->day_of_year() - $self->day_of_week() + 1;
}


1; 

__END__

