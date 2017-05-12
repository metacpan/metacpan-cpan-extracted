#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Duration.pm,v 1.22 2001/07/09 12:11:00 lotr Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Duration -- represent a length of time

=cut

package Net::ICal::Duration;
use strict;

use base qw(Net::ICal::Property);

use Carp;

use constant DEBUG => 0;

=head1 SYNOPSIS

  use Net::ICal;

  # 3 days 6 hours 15 minutes 10 seconds
  $d = Net::ICal::Duration->new("P3DT6H15M10S");

  # 1 hour, in seconds
  $d = Net::ICal::Duration->new(3600);

=head1 DESCRIPTION

I<Duration> represents a length of time, such a 3 days, 30 seconds or
7 weeks. You would use this for representing an abstract block of
time; "I want to have a 1-hour meeting sometime." If you want a
calendar- and timezone-specific block of time, see L<Net::ICal::Period>.

=head1 CONSTRUCTOR

=head2 new(SECONDS | DURATION )

Create a new DURATION object.  It can be constructed from an integer
(the number of seconds since the UNIX epoch), a DURATION string (ala
2445 section 4.3.6), or the individual components (i.e., weeks, days,
hours, minutes and seconds).  See the component update methods below
for caveats on updating these values individually.

=begin testing

use Net::ICal::Duration;

my $d1 = Net::ICal::Duration->new(3600);
ok(defined($d1), "Simple creation from seconds");

ok($d1->as_ical_value eq 'PT1H', "Simple creation from seconds, ical output");

$d1 = undef;
$d1 = Net::ICal::Duration->new("PT10H");

ok(defined($d1), "Simple creation from ical");
ok($d1->as_ical_value eq 'PT10H', "Simple creation from ical, ical output");

# TODO: more elaborate creation tests, and some normalization tests, and
# tests that include days in them

=end testing

=cut

# TODO: clarify what we use %args for. 
sub new {
    my ($class, $value, %args) = @_;

    my $self = $class->SUPER::new('DURATION',
    {
        # Dummy stub for Property.pm
        content => { },

        sign    => { type  => 'volatile',
            doc   => 'Positive or negative',
        },
        nsecs =>   { type  => 'volatile',
            doc   => 'Number of seconds',
        },
        ndays =>   { type  => 'volatile',
            doc   => 'Number of days',
        },
    });

    # If a number is given, convert it to hours, minutes, and seconds,
    # but *don't* extract days -- we want it to represent an absolute
    # amount of time, regardless of timezone
    if ($value) {
        if ($value =~ /^([-+])?\d+$/) { # if we were given an integer time_t
            $self->_set_from_seconds($value); 
        } elsif ($value =~ /^(?:[\-\+])?P/) {   # A standard duration string
            $self->_set_from_ical($value);
        }
    } else {                    # Individual attributes
        $self->set(%args);
        _debug("set method called with args");
    }

    bless $self, $class;
}


#---------------------------------------------------------------------------
# _set_from_ical ($self, $duration_string)
#
# Converts a RFC2445 DURATION format string to an integer number of
# seconds.
#---------------------------------------------------------------------------
sub _set_from_ical {
    my ($self, $str) = @_;

    # RFC 2445 section 4.3.6
    #
    # dur-value  = (["+"] / "-") "P" (dur-date / dur-time / dur-week)
    # dur-date   = dur-day [dur-time]
    # dur-time   = "T" (dur-hour / dur-minute / dur-second)
    # dur-week   = 1*DIGIT "W"
    # dur-hour   = 1*DIGIT "H" [dur-minute]
    # dur-minute = 1*DIGIT "M" [dur-second]
    # dur-second = 1*DIGIT "S"
    # dur-day    = 1*DIGIT "D"

    my ($sign, $magic, $weeks, $days, $hours, $mins, $secs) =
        $str =~ m{
            ([\+\-])?   (?# Sign)
            (P)     (?# 'P' for period? This is our magic character)
            (?:
                (?:(\d+)W)? (?# Weeks)
                (?:(\d+)D)? (?# Days)
            )?
            (?:T        (?# Time prefix)
                (?:(\d+)H)? (?# Hours)
                (?:(\d+)M)? (?# Minutes)
                (?:(\d+)S)? (?# Seconds)
            )?
        }x;

    if (!defined($magic)) {
        carp "Invalid duration: $str";
        return undef;
    }

    $self->sign((defined($sign) && $sign eq '-') ? -1 : 1);

    if (defined($weeks) or defined($days)) {
        $self->_wd([$weeks || 0, $days || 0]);
    }

    if (defined($hours) || defined($mins) || defined($secs)) {
        $self->_hms([$hours || 0, $mins || 0, $secs || 0]);
    }

    return $self;
}

#---------------------------------------------------------------------------
# _set_from_seconds ($self, $num_seconds)
#
# sets internal data storage properly if we were given seconds as a parameter.
#---------------------------------------------------------------------------
sub _set_from_seconds {
    my ($self, $secs) = @_;
            
    $self->sign(($secs < 0) ? -1 : 1);
    # find the number of days, if any
    my $ndays = int ($secs / (24*60*60));
    # now, how many hours/minutes/seconds are there, after
    # days are taken out?
    my $nsecs = $secs % (24*60*60);
    $self->ndays(abs($ndays));
    $self->nsecs(abs($nsecs));


    return $self;
}


=head1 METHODS

=head2 weeks([WEEKS])

Return (or set) the number of weeks in the duration.

=cut

sub weeks   (;$) { 
    my ($self, $args) = @_;
    
    $self->_ret_or_set(\&_wd,  0, @_) 
}

=head2 days([DAYS])

Return (or set) the number of days in the duration.

NOTE: If more than six (6) days are specified, the value will be
normalized, and the weeks portion of the duration will be updated (and
the old value destroyed).  See the I<ndays()> method if you want more
exact control over the "calendar" portion of the duration.

=cut

sub days    (;$) { 
    my ($self, $args) = @_;

    $self->_ret_or_set(\&_wd,  1, $args) 

}

=head2 hours([HOURS])

Return (or set) the number of hours in the duration.

NOTE: Specifying more than 24 hours will NOT increment or update the
number of days in the duration.  The day portion and time portion are
considered separate, since the time portion specifies an absolute amount
of time, whereas the day portion is not absolute due to daylight savings
adjustments.  See the I<nsecs()> method if you want more exact control
over the "absolute" portion of the duration.

=cut

sub hours   (;$) { 
    my ($self, $args) = @_;
    
    $self->_ret_or_set(\&_hms, 0, $args); 
}

=head2 minutes([MINUTES])

Return (or set) the number of minutes in the duration.  If more than
59 minutes are specified, the value will be normalized, and the hours
portion of the duration will be updated (and the old value destroyed).
See the I<nsecs()> method if you want more exact control over the
"absolute" portion of the duration.

=cut

sub minutes (;$) {
    my ($self, $args) = @_;

    $self->_ret_or_set(\&_hms, 1, $args); 
}

=head2 seconds([SECONDS])

Return (or set) the number of seconds in the duration.  If more than 59
seconds are specified, the value will be normalized, and the minutes
AND hours portion of the duration will be updated (and the old values
destroyed).  See the I<nsecs()> method if you want more exact control
over the "absolute" portion of the duration.

=cut

sub seconds (;$) {
    my ($self, $args) = @_;

    $self->_ret_or_set(\&_hms, 2, $args); 
}

=head2 nsecs([SECONDS])

Retrieve or set the number of seconds in the duration.  This sets the
entire "absolute" portion of the duration.

=cut

=head2 ndays([DAYS])

Retrieve or set the number of days in the duration.  This sets the entire
"calendar" portion of the duration.

=cut

=head2 clone()

Return a new copy of the duration.

=cut

sub clone {
  my $self = shift;

  return bless( {%$self},ref($self));

}



=head2 is_valid()

Returns a truth value indicating whether the current object is a valid
duration.

=cut

sub is_valid {
    my ($self) = @_;

    return (defined($self->nsecs) || defined($self->ndays)) ? 1 : 0;
}

=head2 as_int()

Return the length of the duration as seconds.   WARNING -- this folds
in the number of days, assuming that they are always 86400 seconds
long (which is not true twice a year in areas that honor daylight
savings time).  If you're using this for date arithmetic, consider using
the I<add()> method from a L<Net::ICal::Time> object, as this will
behave better.  Otherwise, you might experience some error when working
with times that are specified in a time zone that observes daylight
savings time.

=cut

sub as_int {
    my ($self) = @_;

    my $nsecs = $self->{nsecs}->{value} || 0;
    my $ndays = $self->{ndays}->{value} || 0;
    my $sign  = $self->{sign}->{value}  || 1;
    print "$sign, $ndays, $nsecs \n";
    return $sign*($nsecs+($ndays*24*60*60));
}


=head2 as_ical()

Return the duration as a fragment of an iCal property-value string (e.g.,
":PT2H0M0S").

=begin testing

# This is a really trivial test, I know. 
$d = Net::ICal::Duration->new('PT2H');

ok($d->as_ical eq ':PT2H', 
    "as_ical is correct with hour-only durations");

=end testing

=cut

sub as_ical {
    my ($self) = @_;

    # This is an evil hack. 
    return ":" . $self->as_ical_value;
}

=head2 as_ical_value()

Return the duration in an RFC2445 format value string (e.g., "PT2H0M0S")

=begin testing

$d = Net::ICal::Duration->new('PT2H');

ok($d->as_ical_value eq 'PT2H', 
    "as_ical_value is correct with hour-only durations");

=end testing

=cut

sub as_ical_value {
    my ($self) = @_;

    #print ("entering as_ical_value\n");
    my $tpart = '';
    #print "nsecs is " . $self->{nsecs}->{value} ."\n";
    #print "self hms is " . $self->_hms() ."\n" ;

    if (my $ar_hms = $self->_hms) {
        $tpart = sprintf('T%dH%dM%dS', @$ar_hms);
    }

    my $ar_wd = $self->_wd();
    
    #print "ar_wd is $ar_wd\n";
    my $dpart = '';
    if (defined $ar_wd) {
        my ($weeks, $days) = @$ar_wd;
        #print "$weeks weeks, $days days\n";
        if ($weeks && $days) {
            $dpart = sprintf('%dW%dD', $weeks, $days);
        } elsif ($weeks) {   # (if days = 0)
            $dpart = sprintf('%dW', $weeks);
        } else {
            $dpart = sprintf('%dD', $days);
        }
    }

    #_debug ("self sign value is " . $self->{sign}->{value} . "\n");
    my $value = join('', (($self->{sign}->{value} < 0) ? '-' : ''),
                     'P', $dpart, $tpart);

    # remove any zero components from the time string (-P10D0H -> -P10D)
    $value =~ s/(?<=[^\d])0[WDHMS]//g;

    # return either the time value or PT0S (if the time value is zero).
    return (($value !~ /PT?$/) ? $value : 'PT0S');
}

#---------------------------------------------------------------------------
# $self->_add_or_subtract($duration, $add_or_subtract_flag
#
# Add or subtract $duration from this duration. If $add_or_subtract_flag
# is 1, add; if it's -1, subtract.
#---------------------------------------------------------------------------
sub _add_or_subtract {
    my ($self, $dur2, $dur2mult) = @_;
    #$dur2mult ||= 1;    # Add by default

    unless (UNIVERSAL::isa($dur2, 'Net::ICal::Duration')) {
        my $durstring = $dur2;
        $dur2 = new Net::ICal::Duration($durstring) ||
            warn "Couldn't turn string $durstring into a Net::ICal::Duration";
        #print "making $durstring a duration\n";
    }

    # do math in raw seconds to minimize headaches with units.
    # these conversions could probably be abstracted out.
    my $dur1_nsecs = $self->nsecs || 0;
    my $dur1_ndays = $self->ndays || 0;
    my $dur1_totalsecs = ($dur1_nsecs + ($dur1_ndays * 60*60*24) ) || 0;
    
    my $dur2_nsecs = $dur2->nsecs || 0;
    my $dur2_ndays = $dur2->ndays || 0;
    my $dur2_totalsecs = ($dur2_nsecs + ($dur2_ndays * 60*60*24) ) || 0;

    my ($resultsecs);
    if (defined($dur1_totalsecs) || defined($dur2_totalsecs)) {
        $resultsecs = $dur1_totalsecs + $dur2mult*$dur2_totalsecs;
    }

    # find the number of days, if any
    my $ndays = int ($resultsecs / (24*60*60));
    # now, how many hours/minutes/seconds are there, after
    # days are taken out?
    my $nsecs = $resultsecs % (24*60*60);
    
    # The spec is ambiguous here.  For purposes of determine whether
    # the sign should be positive or negative, we use the sign on the
    # days or (if no days are defined) the seconds.  FIXME when the
    # RFC is clarified on durations
    my $sign;
    if (defined($ndays)) {
        $sign = $ndays < 0 ? -1 : 1;
    } elsif (defined($nsecs)) {
        $sign = $nsecs < 0 ? -1 : 1;
    } else {
        # How would we get here?  Answer: if both of the times were null.
        $sign = undef;
    }

    $self->sign($sign);
    $self->nsecs($nsecs);
    $self->ndays($ndays);

    return $self;
}

=head2 add(DURATION)

Return a new duration that is the sum of this and DURATION.  Does not
modify this object.  Note that the day and time components are added
separately, and the resulting sign is taken only from the days.  RFC 2445
is unclear on this, so you may want to avoid this method, and do your own
calendar/absolute time calculations to ensure that you get the behavior
that you expect in your application.

=begin testing

$d1 = Net::ICal::Duration->new('3600');

#=========================================================================
# first, tests of adding seconds
$d1->add('3600');
ok($d1->as_ical_value eq 'PT2H', "Addition of hours (using seconds) works");

$d1->add('300');
ok($d1->as_ical_value eq 'PT2H5M', "Addition of minutes (using seconds) works");

$d1->add('30');
ok($d1->as_ical_value eq 'PT2H5M30S', "Addition of seconds works");

# I know 1 day != 24 hours, but something like this should be in here.
# perhaps add should warn() on this. --srl
$d1->add(3600*24*3);
ok($d1->as_ical_value eq 'P3DT2H5M30S', "Addition of days (using seconds) works");

#TODO: there should probably be some mixed-unit testing here

#=========================================================================
# now, test adding with iCal strings

$d1 = Net::ICal::Duration->new('3600');

$d1->add('PT1H');
ok($d1->as_ical_value eq 'PT2H', "Addition of hours (using ical period) works");

$d1->add('PT5M');
ok($d1->as_ical_value eq 'PT2H5M', "Addition of minutes (using ical period) works");

$d1->add('PT30S');
ok($d1->as_ical_value eq 'PT2H5M30S', "Addition of seconds (using ical period) works");

# I know 1 day != 24 hours, but something like this should be in here.
# perhaps add should warn() on this. --srl
$d1->add('P3D');
ok($d1->as_ical_value eq 'P3DT2H5M30S', "Addition of days (using ical period) works");

#=========================================================================
# now, test adding with Duration objects 

$d1 = Net::ICal::Duration->new('3600');

$d1->add(Net::ICal::Duration->new('PT1H'));
ok($d1->as_ical_value eq 'PT2H', "Addition of hours (using ical period) works");

$d1->add(Net::ICal::Duration->new('PT5M'));
ok($d1->as_ical_value eq 'PT2H5M', "Addition of minutes (using ical period) works");

$d1->add(Net::ICal::Duration->new('PT30S'));
ok($d1->as_ical_value eq 'PT2H5M30S', "Addition of seconds (using ical period) works");

$d1->add(Net::ICal::Duration->new('P3D'));
ok($d1->as_ical_value eq 'P3DT2H5M30S', "Addition of days (using ical period) works");



=end testing

=cut

sub add {
    my ($self, $arg) = (@_);

    $self->_add_or_subtract($arg, 1);
}

=head2 subtract($duration)

Return a new duration that is the difference between this and DURATION.
Does not modify this object.  Note that the day and time components are
added separately, and the resulting sign is taken only from the days.
RFC 2445 is unclear on this.

=begin testing


=end testing

=cut

sub subtract { 
    my ($self, $arg) = (@_);
    
    $self->_add_or_subtract($arg, -1); 
}

#-------------------------------------------------------------------------
# $self->_hms();
#
# Return an arrayref to hours, minutes, and second components, or undef
# if nsecs is undefined.  If given an arrayref, computes the new number
# of seconds for the duration.  
#-------------------------------------------------------------------------
sub _hms {
    my ($self, $ar_newval) = @_;

    if (defined($ar_newval)) {
        my $new_sec_value = $ar_newval->[0]*3600 +
                            $ar_newval->[1]*60   + $ar_newval->[2];
        $self->nsecs($new_sec_value);
    } 

    #print "nsecs is now " . $self->{nsecs}->{value} . "\n";
    my $nsecs = $self->{nsecs}->{value};
    if (defined($nsecs)) {
        my $hours = int($nsecs/3600);
        my $mins  = int(($nsecs-$hours*3600)/60);
        my $secs  = $nsecs % 60;
        return [ $hours, $mins, $secs ];
    } else {
        print "returning undef\n";
        return undef;
    }
}

#---------------------------------------------------------------------------
# $self->_wd() 
#
# Return an arrayref to weeks and day components, or undef if ndays
# is undefined.  If Given an arrayref, computs the new number of
# days for the duration.  
#---------------------------------------------------------------------------
sub _wd  {
    my ($self, $ar_newval) = @_;

    #print "entering _wd\n";
    
    if (defined($ar_newval)) {
        
        my $new_ndays = $ar_newval->[0]*7 + $ar_newval->[1];
        _debug("trying to set ndays to $new_ndays");
        
        $self->ndays($new_ndays);
        _debug("set ndays to " . $self->{ndays}->{value});
        
    }
    
    #use Data::Dumper; print Dumper $self->{ndays};
    
    if (defined(my $ndays= $self->{ndays}->{value})) {
        my $weeks = int($ndays/7);
        my $days  = $ndays % 7;
        return [ $weeks, $days ];
    } else {
        return undef;
    }
}

#---------------------------------------------------------------------------
# $self->_ret_or_set ($code_ref, $position, $new_value)
#
# Generic function to return or set one of the duration elements
# Specifying an undef for any element will undef the entire portion
# (either days or seconds)
#
#---------------------------------------------------------------------------
sub _ret_or_set (;$) {
    my ($self, $code, $pos, $newval) = @_;

    # get an arrayref to some bit of data in $self, usually either
    # _wd or _hms
    my $ar_cur = &{$code}($self);
    
    # if we were given a new value for the data in position $pos,
    # set that data. 
    if (defined($newval)) {
        $ar_cur = [ ] unless defined($ar_cur);
        $ar_cur->[$pos] = $newval;
        &{$code}($self, $ar_cur);
    } else {
        undef $ar_cur;
        &{$code}($self, undef);
    }
    
    return defined($ar_cur) ? $ar_cur->[$pos] : undef;
}


#---------------------------------------------------------------------------
# _debug ($debug_message)
#
# prints a debug message if DEBUG is set to 1.
#---------------------------------------------------------------------------
sub _debug {
    my ($debug_message) = @_;

    print "$debug_message\n" if DEBUG;
    return 1;
}

=head1 BUGS

   * RFC 2445 is unclear about how days work in durations.
     This code might need to be modified if/when section 4.3.6
     is updated

   * According to the RFC, there's no limit on how many
     seconds, minutes, etc. can be in a duration.  However,
     this implementation always normalizes the day and time
     components, and always reports hours, minutes, and seconds
     (even if one or more of them are zero or weren't initially
     defined).

=head1 AUTHOR

See the Reefknot AUTHORS file, or

   http://reefknot.sourceforge.net/

=cut

1;

=head1 SEE ALSO

More documentation pointers can be found in L<Net::ICal>.

=cut
