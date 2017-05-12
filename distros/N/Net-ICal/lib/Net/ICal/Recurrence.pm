#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Recurrence.pm,v 1.14 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Recurrence -- Represent a single recurrence rule

=cut

package Net::ICal::Recurrence;
use strict; 

use base qw(Net::ICal::Property);

use Carp;

#TODO: remove Date::Calc usage from this module; it's not epoch-safe.
use Date::Calc qw(:all);
use POSIX qw(strftime);
use Time::Local;

=head1 SYNOPSIS

  use Net::ICal::Recurrence;
  $rrule = new Net::ICal::Recurrence([ OPTION_PAIRS ]) ;

=head1 WARNING

This implementation of Recurrences needs serious work and
refactoring for clarity. The API is not stable. 
Patches and suggestions welcome.

=head1 DESCRIPTION

I<Recurrence> holds a single recurrence property, ala section 4.3.10 of
RFC 2445.

=cut

my %freqorder = do {
   my $i = 0;
   map { $_ => $i++ } qw(SECONDLY MINUTELY HOURLY DAILY WEEKLY MONTHLY YEARLY);
};

my @oDoW = qw[ SU MO TU WE TH FR SA SU MO TU WE TH FR SA SU MO TU WE TH FR SA ];
my %oDoW = map { $oDoW[$_] => $_ } (0..6);

my $enum_freq      = [ qw(SECONDLY MINUTELY HOURLY DAILY),
                       qw(WEEKLY MONTHLY YEARLY) ];
my $enum_wday      = [ qw(MO TU WE TH FR SA SU) ];
my $is_weekdaynum  = qr[^(?:(?:-|\+)?\d+)?(?:SU|MO|TU|WE|TH|FR|SA)$]i;

# Simple ranges (sets with end value that doesn't change)
my $is_second      = [0, 59];
my $is_minute      = [0, 59];
my $is_hour        = [0, 23];
my $is_monthnum    = [1, 12];

# Ranges with variable upper boundaries (negative offsets supported)
my $is_ordyrday    = [1, 366];
my $is_ordmoday    = [1,  31];
my $is_ordwk       = [1,  53];


=head1 CONSTRUCTOR

=head2 new([ OPTIONS_PAIRS ])

Create a new recurrence rule.  Values for any of the accessors (below) may
be specified at intialization time.

=begin testing

# TODO: write tests for this module, cleaning up the API as necessary.
TODO: {
    local $TODO = 'write tests for N::I::Recurrence';
    ok(0, 'write tests for Net::ICal::Recurrence');

}
=end testing
=cut

sub new {
   my $class = shift;
   my ($value, %args) = @_;
   $args{content} = $value;

   return $class->_create(%args);
}

=head2 new_from_ical($ical_string)

Create a new recurrence rule from an iCalendar string.  

=cut

sub new_from_ical {
   my $class = shift;
   my $ical  = shift;

   my ($name, $delim, $rest) = $ical =~ /^(\w+)([:;])(.*)/;
   return undef unless $name;
   my $fdelim = $delim eq ';' ? ':' : ';';
   my $self = $class->_create();
   my @pairs = split(/[=$fdelim]/, $rest);
   while (my ($k, $v) = splice(@pairs, 0, 2)) {
      $self->set(lc($k), $v);
   }
   return $self;
}





=head2 as_ical_value()

Return an iCal format RRULE string

=cut

sub as_ical_value () {
  my $self = shift;

  my @comps;

  # FREQ is always forced to to the front of list
  foreach my $key (sort { $a eq 'freq' ? -1 : $b eq 'freq' ? 1 : ($a cmp $b) }
                        keys %$self)
  {
    next if $key eq 'name' || $key eq 'content';
    my $val = $self->{$key};
    if (exists($val->{value}) && defined($val->{value})) {
      my $value = $val->{value};
      if (!ref($value)) {			# single value
	push(@comps, uc($key).'='.uc($value));
      } elsif (ref($value) eq 'ARRAY') {	# list of values
	push(@comps, uc($key).'='.uc(join(',', @$value)));
      } elsif (ref($value) =~ /::/) {		# Internal type
	push(@comps, uc($key).'='.$value->as_ical_value);
      } else {
	croak "'$key' component of recurrence has an unexpected value ($value)";
      }
    }
  }
  return ':'.join(';', @comps);
}

sub as_ical () { (shift)->as_ical_value() }

=head2 by()

Return a hash reference containing the BY* elements.  Keys are DAY,
MONTH, etc., and the values are hashrefs with one key per element.  E.g.,
a RRULE with BYMONTH=6,8;BYDAY=1MO,2WE,FR would be structured as follows:

  {
      DAY   => { MO => 1, WE => 2, FR => undef },
      MONTH => { 6 => undef, 8 => undef }
  }

=cut

sub by () {
   my $self = shift;

   my %by;
   foreach my $bfreq (keys %$self) {
      next unless $bfreq =~ /^by(.*)/;
      my $bywhat = uc($1);
      next unless defined $self->{$bfreq}->{value};
      foreach my $value (@{$self->{$bfreq}->{value}}) {
	 if ($bywhat eq 'DAY') {
	    my ($ord, $day) = $value =~ /^([-+]?\d+)?(MO|TU|WE|TH|FR|SA|SU)/;
	    if ($day) {
	       $by{$bywhat}->{$day} = $ord;
	    } else {
	       warn "BYDAY element unparseable: $value";
	    }
	 } else {
	    $by{$bywhat}->{$value} = undef;
	 }
      }
   }

   return \%by;
}

sub occurrences ($) {
   my $self = shift;
   my $comp = shift;
   my $reqperiod = shift || croak "Missing period parameter for occurrences()";

   # Define period start and end as simple int's
   my ($pstart, $pend) = ($reqperiod->start->as_int, $reqperiod->end->as_int);
  
   # Get this event's dtstart, and bump up req
   my $dtstart = $comp->dtstart; # TODO: What do we do if this isn't defined?
   if (!defined($dtstart)) {
      carp "Component has no DTSTART.  Can't determine occurrences.";
      return [ ];
   }

   # When does each occurence of this event end?  Is it specified with
   # a duration, or a hard end time?
   my $dtend    = $comp->dtend;
   my $duration = $comp->duration;

   if (!$duration && $dtend) {
      $duration = Net::ICal::Duration->new($dtend->as_int - $dtstart->as_int);
   }

   my @occurrences;

   # Here we go...

   # For now, we try to set this to the beginning of the event, not
   # the beginning of the period.  We'll get this working the brute force
   # way (preferably bug-free) before we get more exotic with the math


   # Fortunately, RFC2445 says that the DTSTART *must* be the first
   # occurrence.

   # Does this recurrence have an end time specified?
   my $until;
   if (defined(my $runtil = $self->until)) {
      $until = $runtil->as_int;
   }

   my $ccount = 1;			# Keep track of the occurence count
   my $count = $self->count();

   # This is ignored for now
   my %bysetpos;
   my $bysetpos = $self->bysetpos();
   if (defined($bysetpos)) {
      %bysetpos = map { $_ => 1 } split(/\s*,\s*/, $bysetpos);
   }

   my %bywhat = %{$self->by};


   # The "candidate occurrence" queue
   my @coqueue = ( );
   # The event always specifies the first candidate occurrence
   # FIXME: just make the this the first occurrence, not the first candidate
   push(@coqueue, $dtstart);

   while (@coqueue) {
      my $cstart = shift @coqueue;

      # Is event bounded by an UNTIL?
      last if defined($until) && $cstart->as_int > $until;

      # Is event bounded by a recurrence limit?
      last if defined($count) && $ccount > $count;

      # Have we reached the end of the viewing period?
      last if $cstart->as_int > $pend;

      # Get the goods on this start time
      # FIXME:  Hardcoded local time zone!
      my ($ss, $mm, $hh, $DD, $MM, $YY, $pDoW) = localtime($cstart->as_int);
      #my $DoW = (qw(SU MO TU WE TH FR SA))[$pDoW];
      my $DoW = $self->_tz_dow($cstart);
      my $MoY = $MM+1;
      my $YYYY = $YY+1900;

      # Check the BY* rules one-by-one -- these are *restrictions* only
      # (i.e., they determine whether this occurrence is valid).
      # These apply where BY* rule specifies a unit *less* than or the
      # same as the frequency (e.g., if FREQ=DAILY, and BYMONTH=TU,TH,
      # then this occurrence is invalidated if it falls outside those days,
      # and the count is DECREMENTED.

      # FIXME
      # For now, we IGNORE BY* where the * is an interval that is
      # *less* than the recurrence frequency.  This violates the spec.
      # (is this even necessary if a DURATION hasn't been specified?)

      # BYDAY
      if (defined(my $hr_byday = $bywhat{'DAY'})) {
	 # If this day doesn't match any of the keys, skip it
	 if (!exists($hr_byday->{$DoW})) {
	    #warn "This day($DoW) isn't in the BYDAY spec";
	    goto INCREMENT_CSTART;
	 }
      }

      # We have a winner.  We must increment the count even if it's not
      # a candidate due to it occurring before the period
      $ccount++;

      # Does this occurrence start before the viewing period?
      goto INCREMENT_CSTART if $cstart->as_int < $pstart;

      # Push into the occurrence array
      if ($duration) {
	 push(@occurrences, Net::ICal::Period->new($cstart, $duration));
      } else {
	 push(@occurrences, $cstart);
      }

      INCREMENT_CSTART:
      # This is only done when the candidate queue is empty
      $self->_supplement_queue(\@coqueue, \%bywhat, $dtstart, $cstart)
	 unless @coqueue;
   }

   return \@occurrences;
}

=head1 METHODS

All of the methods that set multi-valued attributes (e.g., I<bysecond>)
accept either a single value or a reference to an array.

=head2 freq (FREQ)

Specify the frequency of the recurrence.  Allowable values are:

  SECONDLY MINUTELY HOURLY DAILY WEEKLY MONTHLY YEARLY

=cut

=head2 count(N)

Specify that the recurrence rule occurs for N recurrences, at most.
May not be used in conjunction with I<until>.

=cut

=head2 until(ICAL_TIME)

Specify that the recurrence rule occurs until ICAL_TIME at the latest.
ICAL_TIME is a Net::ICal::Time object.  May not be used in conjunction
with I<count>.

=cut

=head2 interval(N)

Specify how often the recurrence rule repeats.  Defaults to '1'.

=cut

=head2 bysecond([ SECOND , ... ])

Specify the valid of seconds within a minute.  SECONDs range from 0 to 59.
Use an arrayref to specify more than one value.

=cut

=head2 byminute([ MINUTE , ... ])

Specify the valid of minutes within an hour.  MINUTEs range from 0 to 59.
Use an arrayref to specify more than one value.

=cut

=head2 byhour([ HOUR , ... ])

Specify the valid of hours within a day.  HOURs range from 0 to 23.
Use an arrayref to specify more than one value.

=cut

=head2 byday([ WDAY , ... ])

Specify the valid weekdays.  Weekdays must be one of

  MO TU WE TH FR SA SU

and may be preceded with an ordinal week number.  If the recurrence
frequency is MONTHLY, the ordinal specifies the valid week within the
month.  If the recurrence frequency is YEARLY, the ordinal specify the
valid week within the year.  A negative ordinal specifys an offset from
the end of the month or year.

=cut

=head2 bymonthday([ MONTHDAY, ... ])

Specify the valid days within the month.  A negative number specifies an
offset from the end of the month.

=cut

=head2 byyearday([ YEARDAY, ... ])

Specify the valid day(s) within the year (i.e., 1 is January 1st).
A negative number specifies an offset from the end of the year.

=cut

=head2 byweekno([ WEEKNO, ... ])

Specify the valid week(s) within the year.  A negative number specifies
an offset from the end of the year.

=cut

=head2 bymonth([ MONTH, ... ])

Specify the valid months within the year.

=cut

=head2 bysetpos([ N, ... ])

Specify the valid recurrences for the recurrence rule.  Use this when
you need something more complex than INTERVAL.  N may be negative, and
would specify an offset from the last occurrence specified by another
attribute (-1 is the last occurrence).

=cut

=head2 wkst(WEEKDAY)

Specify the starting day of the week as applicable to week calculations.
The default is MO.  The allowable options are the same weekday codes as
for I<byday>.

=cut


=head1 INTERNAL-ONLY METHODS

These still need to be documented and/or revamped to be more readable
by mere mortals.

=head2 _create($classname, $arghashref)

A background method to new() that creates the internal
data storage map for Class::MethodMapper. 

=cut
sub _create ($;%) {
   my $class = shift;
   my @args  = @_;

   return $class->SUPER::new(
     'RECUR',
     {

       # for Property.pm
       content => {  type		=> 'volatile',
		     doc		=> 'Full value of property',
		     #domain	=> 'reclass',
		     #options	=> { default => 'Net::ICal::Recurrence' },
		     value 	=> undef,
		  },

       # "FREQ"=freq
       # freq       = "SECONDLY" / "MINUTELY" / "HOURLY" / "DAILY"
       #            / "WEEKLY" / "MONTHLY" / "YEARLY"
       freq => { type    => 'volatile',
		 doc     => 'Recurrence frequency',
		 domain  => 'enum',
		 options => $enum_freq,
       },

       # ( ";" "COUNT" "=" 1*DIGIT )
       count => { type    => 'volatile',
		  doc     => 'End of recurrence range',
		  domain  => 'positive_int',
       },

       # ( ";" "UNTIL" "=" enddate )
       until => { type    => 'volatile',
		  doc     => 'End of recurrence range',
		  domain  => 'ref',
		  options => 'Net::ICal::Time',
       },
       # ( ";" "INTERVAL" "=" 1*DIGIT )
       interval => { type    => 'volatile',
		     doc     => 'Event occurs every Nth instance',
		     domain  => 'positive_int',
		     value	=> 1,
       },

       # ( ";" "BYSECOND" "=" byseclist )        /
       # byseclist  = seconds / ( seconds *("," seconds) )
       # seconds    = 1DIGIT / 2DIGIT       ;0 to 59
       bysecond => { type    => 'volatile',
		     doc     => 'Valid seconds within each minute',
		     domain  => 'multi_fixed_range',
		     options	=> $is_second,
       },

       # ( ";" "BYMINUTE" "=" byminlist )        /
       # byminlist  = minutes / ( minutes *("," minutes) )
       # minutes    = 1DIGIT / 2DIGIT       ;0 to 59
       byminute => { type    => 'volatile',
		     doc     => 'Valid minutes within each hour',
		     domain  => 'multi_fixed_range',
		     options	=> $is_minute,
       },

       # ( ";" "BYHOUR" "=" byhrlist )           /
       # byhrlist   = hour / ( hour *("," hour) )
       # hour       = 1DIGIT / 2DIGIT       ;0 to 23
       byhour => { type    => 'volatile',
		   doc     => 'Valid hours within each day',
		   domain  => 'multi_fixed_range',
		   options	=> $is_hour,
       },

       # ( ";" "BYDAY" "=" bywdaylist )          /
       # bywdaylist = weekdaynum / ( weekdaynum *("," weekdaynum) )
       # weekdaynum = [([plus] ordwk / minus ordwk)] weekday
       # plus       = "+"
       # minus      = "-"
       # ordwk      = 1DIGIT / 2DIGIT       ;1 to 53
       byday => { type    => 'volatile',
		  doc     => 'Valid weekdsays within week',
		  domain  => 'multi_match',
		  options => $is_weekdaynum,
       },

       # ( ";" "BYMONTHDAY" "=" bymodaylist )    /
       # bymodaylist = monthdaynum / ( monthdaynum *("," monthdaynum) )
       # monthdaynum = ([plus] ordmoday) / (minus ordmoday)
       # ordmoday   = 1DIGIT / 2DIGIT       ;1 to 31
       bymonthday => { type    => 'volatile',
		       doc     => 'Valid days within week',
		       domain  => 'multi_ordinal_range',
		       options => $is_ordmoday,
       },

       # ( ";" "BYYEARDAY" "=" byyrdaylist )     /
       # byyrdaylist = yeardaynum / ( yeardaynum *("," yeardaynum) )
       # yeardaynum = ([plus] ordyrday) / (minus ordyrday)
       # plus       = "+"
       # minus      = "-"
       # ordyrday   = 1DIGIT / 2DIGIT / 3DIGIT      ;1 to 366
       byyearday => { type    => 'volatile',
		      doc     => 'Valid days within year',
		      domain  => 'multi_ordinal_range',
		      options => $is_ordyrday,
       },

       # ( ";" "BYWEEKNO" "=" bywknolist )       /
       # bywknolist = weeknum / ( weeknum *("," weeknum) )
       # weeknum    = ([plus] ordwk) / (minus ordwk)
       # plus       = "+"
       # minus      = "-"
       # ordwk      = 1DIGIT / 2DIGIT       ;1 to 53
       byweekno => { type    => 'volatile',
		     doc     => 'Valid weeks within year',
		     domain	=> 'multi_ordinal_range',
		     options	=> $is_ordwk,
       },

       # ( ";" "BYMONTH" "=" bymolist )          /
       # bymolist   = monthnum / ( monthnum *("," monthnum) )
       # monthnum   = 1DIGIT / 2DIGIT       ;1 to 12
       bymonth => { type    => 'volatile',
		    doc     => 'Valid months within year',
		    domain  => 'multi_fixed_range',
		    options	=> $is_monthnum,
       },

       # ( ";" "BYSETPOS" "=" bysplist )         /
       # bysplist   = setposday / ( setposday *("," setposday) )
       # setposday  = yeardaynum
       # yeardaynum = ([plus] ordyrday) / (minus ordyrday)
       # plus       = "+"
       # minus      = "-"
       # ordyrday   = 1DIGIT / 2DIGIT / 3DIGIT      ;1 to 366
       bysetpos => { type    => 'volatile',
		     doc     => 'Valid occurrences of recurrence rule',
		     domain  => 'multi_ordinal_range',
		     options => $is_ordyrday,
       },

       # ( ";" "WKST" "=" weekday )              /
       wkst => { type    => 'volatile',
		 doc     => 'First day of week',
		 domain  => 'enum',
		 options => $enum_wday,
		 value   => 'MO',
       },
     },
     @args);
}


=head2 _positive_int_set

Set a value only if it's a positive integer (ala 1*DIGIT)

=cut


sub _positive_int_set ($$) {
  my $self = shift;
  my ($key, $val) = @_;

  if (!defined($val) || ref($val) || int($val) != $val || $val < 1) {
    carp "'$val' is not a positive integer";
    return undef;
  }

  $self->{$key}->{value} = $val;
}

=head2 _multi_fixed_range_set

Set a value only if it falls within a range (inclusive)

=cut

sub _multi_fixed_range_set ($$) {
  my $self = shift;
  my ($key, $vals) = @_;

  my $ar_minmax = $self->{$key}->{options} ||
    croak "Missing required 'options' for multi_fixed_range check on '$key'";

  my ($min, $max) = @$ar_minmax;

  my @vals;
  if (ref($vals) eq 'ARRAY') {
    @vals = @$vals;
  } elsif (!ref($vals)) {
    @vals = ($vals);
  } else {
    warn "value for $key is neither a scalar nor an array reference";
    return undef;
  }

  foreach my $val (@vals) {
    if (!defined($val)) {
      carp "undefined values can't be within a numeric range";
      return undef;
    }
    if ($val < $min || $val > $max) {
      carp "'$val' is outside of allowable range of $min to $max";
      return undef;
    }
  }

  $self->{$key}->{value} = \@vals;
}


=head2 _multi_match_set

Set a value if all of the elements match a regular expression

=cut
sub _multi_match_set ($$) {
  my $self = shift;
  my ($key, $vals) = @_;

  my $regex = $self->{$key}->{options} ||
    croak "Missing required 'options' for multi_match check on '$key'";

  my @vals;
  if (ref($vals) eq 'ARRAY') {
    @vals = @$vals;
  } elsif (!ref($vals)) {
    if ($vals =~ /,/) {
      @vals = split(/,/, $vals);
    } else {
      @vals = ($vals);
    }
  } else {
    warn "value for $key is neither a scalar nor an array reference";
    return undef;
  }

  foreach my $val (@vals) {
    if (!defined($val)) {
      carp "undefined values not permitted";
      return undef;
    }
    if ($val !~ $regex) {
      carp "'$val' is not an allowable value";
      return undef;
    }
  }

  $self->{$key}->{value} = \@vals;
}

=head2 _multi_ordinal_range_set

Set a value if all of the elements are within a range, regardless of sign

=cut

sub _multi_ordinal_range_set ($$) {
  my $self = shift;
  my ($key, $vals) = @_;

  my $ar_minmax = $self->{$key}->{options} ||
    croak "Missing required 'options' for multi_ordinal_range check on '$key'";

  my ($min, $max) = @$ar_minmax;

  my @vals;
  if (ref($vals) eq 'ARRAY') {
    @vals = @$vals;
  } elsif (!ref($vals)) {
    @vals = ($vals);
  } else {
    warn "value for $key is neither a scalar nor an array reference";
    return undef;
  }

  foreach my $val (@vals) {
    if (!defined($val)) {
      carp "undefined values can't be within a numeric range";
      return undef;
    }
    if (abs($val) < $min || abs($val) > $max) {
      carp "'$val' is outside of allowable range ".
           "of -$max to -$min and $min to $max";
      return undef;
    }
  }

  $self->{$key}->{value} = \@vals;
}

=head2 _supplement_queue

TODO: document this routine and refactor it.

=cut

sub _supplement_queue ($$) {
   my $self = shift;

   my $ar_ocqueue = shift;
   my %bywhat	  = %{shift()};
   my $dtstart    = shift;
   my $cstart     = shift;

   my $rfreq     = $self->freq()        || 'DAILY';
   my $freqorder = $freqorder{$rfreq};
   my $rinterval = int($self->interval) || 1;


   if ($rfreq eq 'DAILY') {
      my $toadd = Net::ICal::Duration->new(sprintf('P%dD', $rinterval));
      push(@$ar_ocqueue, $cstart->add($toadd));
   } elsif ($rfreq eq 'WEEKLY') {
      # Handle the simplest case first -- no "BY*" components
      # components
      # TODO: add BY{WEEKNO,MONTH,MONTHDAY,YEARDAY}
      if (keys(%bywhat) == 0) {
	 my $toadd = Net::ICal::Duration->new(sprintf('P%dW', $rinterval));
	 push(@$ar_ocqueue, $cstart->add($toadd));
      } else {
	 if (my $hr_days = $bywhat{DAY}) {
	    # Are we still working on the first week?  If so, populate any
	    # remaining BYDAY's that apply to this week
	    my @newdays;
	    if ($cstart->as_int == $dtstart->as_int) {
	       my ($this_dow) =
		  $self->_order_days_of_week($self->_tz_dow($cstart));
	       my @tDoW = $self->_order_days_of_week(keys %$hr_days);
	       my @offsets;
	       foreach my $tDoW (@tDoW) {
		  next if $tDoW <= $this_dow;
		  push(@offsets, $tDoW - $this_dow);
	       }
	       @newdays = $self->_compute_set_of_days($cstart, @offsets)
		  if @offsets;
	    }

	    if (!@newdays) {
	       # Find out what the beginning of this week is, increment
	       # it by seven days, and push in the appropriate days from
	       # the BYDAY list.  The day of week of this event must be
	       # determined within the time's preferred timezone.  The Time
	       # object doesn't currently track this, hence the need to run
	       # it back through localtime.
	       my $nextweek = $self->_first_day_of_next_week($cstart,
	                                                     $rinterval);

	       # And get that next set of days
	       @newdays =
		  $self->_compute_set_of_days($nextweek,
					      $self->_order_days_of_week(keys %$hr_days));
	    }
	    push(@$ar_ocqueue, @newdays);
	 }
      }
   } elsif ($rfreq eq 'MONTHLY') {
      # Handle the simplest case first -- no "BY*" components
      # components
      if (keys(%bywhat) == 0) {
	 # Start with the DTSTART rather than current time to preserve
	 # the day of month -- adjust down only if necessary
	 my $nexttime = $dtstart->clone;
	 my $nextMoY  = $cstart->month + $rinterval;
	 my $nextYYYY = $cstart->year;
	 my $nextDD   = $dtstart->day;
	 while ($nextMoY > 12) {
	    $nextMoY -= 12;
	    $nextYYYY++;
	 }
	 # Move back to last day if the corresponding day in the DTSTART
	 # is beyond the end of this month
	 my $DiM = Days_in_Month($nextYYYY, $nextMoY);
	 $nexttime->day($DiM) if $nextDD > $DiM;
	 $nexttime->year($nextYYYY);
	 $nexttime->month($nextMoY);
	 push(@$ar_ocqueue, $nexttime);
      } else {
	 if (my $hr_mdays = $bywhat{MONTHDAY}) {
	    my ($nYYYY, $nMoY, $nDD) =
	       ($cstart->year, $cstart->month, $cstart->day);
	    my $last_day_of_month;
	    my @newdays;
	    # Are we still working on the first month?  If so, populate any
	    # remaining BYMONTHDAY's that apply to this month
	    if ($cstart->as_int == $dtstart->as_int) {
	       my $DiM = Days_in_Month($nYYYY, $nMoY);
	       my @DDs;
	       foreach my $dayord (keys %$hr_mdays) {
		  if ($dayord > 1) {
		     push(@DDs, $dayord > $DiM ? $DiM : $dayord);
		  } elsif ($dayord < 0) {
		     my $newday = $DiM + $dayord + 1;
		     push(@DDs, $newday < 1 ? 1 : $newday);
		  }
	       }
	       # Now, prune out the events for days before the dtstart DD
	       my $sDD = $dtstart->day;
	       foreach my $thisDD (sort @DDs) {
		  next if $thisDD <= $sDD;
		  my $newtime = $dtstart->clone();
		  $newtime->day($thisDD);
		  push(@newdays, $newtime);
	       }
	    }

	    # We're either in the next month, or there were no valid
	    # occurrence candidates left in the first month
	    if (!@newdays) {
	       $nMoY += $rinterval;
	       while ($nMoY > 12) {
		  $nMoY -= 12;
		  $nYYYY++;
	       }
	       my $firsttime = $dtstart->clone();
	       my $DiM = Days_in_Month($nYYYY, $nMoY);
	       my @DDs;
	       foreach my $dayord (keys %$hr_mdays) {
		  if ($dayord > 1) {
		     push(@DDs, $dayord > $DiM ? $DiM : $dayord);
		  } elsif ($dayord < 0) {
		     my $newday = $DiM + $dayord + 1;
		     push(@DDs, $newday < 1 ? 1 : $newday);
		  }
	       }
	       foreach my $thisDD (sort @DDs) {
		  my $newtime = $dtstart->clone();
		  # FIXME: This gets around the auto-normalize
		  $newtime->day(1);
		  $newtime->month($nMoY);
		  $newtime->year($nYYYY);
		  # FIXME: End of workaround
		  $newtime->day($thisDD);
		  push(@newdays, $newtime);
	       }
	    }
	    push(@$ar_ocqueue, @newdays);
	 }
      }
   } else {
      croak "Can't handle frequency of $rfreq just yet...";
   }

}

#########
# FIXME #
##########################################################################
# Yes, folks the following code  is truly bizarre and probably unnecessary
# but I'm leaving in for now until I can thow some of this WKST support
# into the ::Time module.  Off hand, the only reason I can think of that
# WKST even matters is computing the week number within the year, but I
# must've been smoking some good crack when I wrote this.  -SHUTTON
##########################################################################


=head2 _order_days_of_week

Order a set of weekdays according to the WKST setting in the rule
E.g., if MO is the first day of the week, and we're given TU, TH, FR, SU
then return 1, 3, 4, and 6 (the zero-index offsets from Monday)

=cut
sub _order_days_of_week {
   my $self = shift;
   my @days = @_;

   my $wkst_day = $oDoW{$self->wkst() || 'SU'};
   
   # Prepare a map order to speed things up
   # TODO: cache this or set it up when the module loads
   my %order = map { $oDoW[($_+$wkst_day) % 7] => $_ } (0 .. 6);

   # Return the day indices based on this order
   return sort @order{@days};
}

=head2 _first_day_of_next_week

TODO: document the parameters for this.

=cut
sub _first_day_of_next_week {
   my $self = shift;
   my $time = shift;
   my $interval = shift;

   local %ENV;
   $ENV{TZ} = $time->timezone || '';
   my $cDoW = (localtime($time->as_int))[6];

   # Compute the beginning of the week
   my $wkst_day = $self->wkst() || 'SU';
   my $week_began_days_ago = ($cDoW+7 - $oDoW{$wkst_day}) % 7;

   # Build the new day
   my ($bYYYY, $bMoY, $bDD) = Add_Delta_Days($time->year,
					     $time->month,
					     $time->day,
					     -1*$week_began_days_ago+7*$interval);
   my $bow = $time->clone();
   $bow->year($bYYYY);
   $bow->month($bMoY);
   $bow->day($bDD);

   return $bow;
}

=head2 _first_day_of_next_month

TODO: document the parameters for this.

=cut

sub _first_day_of_next_month {
   my $self = shift;
   my $time = shift;

   my $newtime = $time->clone();
   my ($YYYY, $MoY) = ($newtime->year, $newtime->month);
   if (++$MoY > 12) {
      $MoY = 1;
      $YYYY++;
   }
   $newtime->year($YYYY);
   $newtime->month($MoY);

   return $newtime;
}

=head2 _tz_dow

Return the day of the week that this time falls on, adjusted for time zone

=cut
sub _tz_dow {
   my $self = shift;
   my $time = shift;

   local %ENV;
   $ENV{TZ} = $time->timezone || '';
   return $oDoW[(localtime($time->as_int))[6]];
}

=head2 _days_till_next_week

TODO: document the parameters for this.

=cut

sub _days_till_next_week {
   my $self = shift;
   my $time = shift;

   return 7 - $self->_tz_dow($time);
}

=head2 _compute_set_of_days

TODO: document the parameters for this.

=cut

sub _compute_set_of_days {
   my $self = shift;

   my $start      = shift;
   my @increments = @_;

   my ($sYYYY, $sMoY, $sDD) = ($start->year, $start->month, $start->day);
   my ($HH, $MM, $SS)       = ($start->year, $start->month, $start->day);
   my @days;
   foreach my $inc (@increments) {
      my $newtime = $start->clone();
      my ($nYYYY, $nMoY, $nDD) = Add_Delta_Days($sYYYY, $sMoY, $sDD, $inc);
      $newtime->year($nYYYY);
      $newtime->month($nMoY);
      $newtime->day($nDD);
      push(@days, $newtime);
   }
   return @days;
}

=head1 SEE ALSO

L<Net::ICal>

=cut

1;
