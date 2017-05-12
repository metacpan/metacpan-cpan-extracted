########################################################################
# File:     DateTime.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: DateTime.pm,v 1.6 2000/02/08 02:36:40 winters Exp winters $
#
# A date and time class.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DataType::DateTime;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

### we are a subclass of the all-powerful Persistent::DataType::Base class ###
use Persistent::DataType::Base;
@ISA = qw(Persistent::DataType::Base);

use Carp;

### copy version number from superclass ###
$VERSION = $Persistent::DataType::Base::VERSION;
$REVISION = (qw$Revision: 1.6 $)[1];

=head1 NAME

Persistent::DataType::DateTime - A Date and Time Class

=head1 SYNOPSIS

  use Persistent::DataType::DateTime;
  use English;

  eval {  ### in case an exception is thrown ###

    ### allocate a date ###
    my $date = new Persistent::DataType::DateTime(localtime);

    ### get/set value of date ###
    $value = $date->value($year, $month, $day,
			  $hours, $minutes, $seconds);

    ### get/set year of the date ###
    $year = $date->year($new_year);

    ### get/set month of the date ###
    $month = $date->month($new_month);

    ### get/set day of the date ###
    $day = $date->day($new_day);

    ### get/set hours of the date ###
    $hours = $date->hours($new_hours);

    ### get/set minutes of the date ###
    $minutes = $date->minutes($new_minutes);

    ### get/set seconds of the date ###
    $seconds = $date->seconds($new_seconds);

    ### returns 'cmp' for dates ###
    my $cmp_op = $date->get_compare_op();
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a date and time class used by the Persistent framework of
classes to implement the attributes of objects.  This class provides
methods for accessing a date in a variety of formats.

This class is usually not invoked directly, at least not when used
with the Persistent framework of classes.  However, the constructor
arguments of this class are usually of interest when defining the
attributes of a Persistent object since the I<add_attribute> method of
the Persistent classes instantiates this class directly.  Also, the
arguments to the I<value> method are of interest when dealing with the
accessor methods of the Persistent classes since the accessor methods
pass their arguments to the I<value> method and return the string
value from the I<value> method.

This class is part of the Persistent base package which is available
from:

  http://www.bigsnow.org/persistent
  ftp://ftp.bigsnow.org/pub/persistent

=head1 DESCRIPTION

Before we get started describing the methods in detail, it should be
noted that all error handling in this class is done with exceptions.
So you should wrap an eval block around all of your code.  Please see
the L<Persistent> documentation for more information on exception
handling in Perl.

=head1 METHODS

=cut

########################################################################
#
# --------------------------------------------------------------------
# PUBLIC ABSTRACT METHODS OVERRIDDEN (REDEFINED) FROM THE PARENT CLASS
# --------------------------------------------------------------------
#
########################################################################

########################################################################
# initialize
########################################################################

=head2 Constructor -- Create a New DateTime Object

  use Persistent::DataType::DateTime;

  eval {
    $date = new Persistent::DataType::DateTime($datestring);
    $date = new Persistent::DataType::DateTime('now');
    $date = new Persistent::DataType::DateTime('');
    $date = new Persistent::DataType::DateTime(undef);
    $date = new Persistent::DataType::DateTime($year, $month, $day,
					       $hour, $min, $sec);
    $date = new Persistent::DataType::DateTime(localtime);
  };
  croak "Exception caught: $@" if $@;

Initializes a DateTime object.  This method throws Perl execeptions so
use it with an eval block.

This constructor accepts several forms of arguments:

=over 4

=item I<$datestring>

If the sole argument is a string, it is assumed to contain the date
and time in the following format:

  YYYY-MM-DD hh:mm:ss
           or
  YYYY/MM/DD hh:mm:ss

This is also the format that is returned by the I<value> method of
this object.

Another valid format to pass is the following:

  DD-Mon-YYYY

where Mon is the three letter abbreviation for the month.  The case of
the letters is not sensitive (i.e. jan or Jan or JAN is alright).

=item I<'now'>

If the sole argument is the word 'now', then the current date and time
are used.

=item I<undef> or I<the empty string ('')>

If the sole argument is undef or the empty string (''), then the date
and time are set to undef.

=item I<$year, $month, $day, $hour, $min, $sec>

If more than one argument is given (and less than 7), it is assumed
that the date and time are being given as a series of integers in the
above order where their formats are the following:

  $year = 0 .. 9999  ### 4 digit year ###
  $month = 1 .. 12
  $day = 1 .. 31
  $hours = 0 .. 23
  $minutes = 0 .. 59
  $seconds = 0 .. 59

=item I<$sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst>

If more than six arguments are passed, it is assumed that the date and
time are being given as a series of integers in the above order, which
happens to be the same order as the array that the Perl built-ins,
localtime and gmtime, return.  See the I<perlfunc> manpage for more
information.

=back

=cut

sub initialize {
  my $this = shift;

  $this->_trace();

  $this->value(@_);
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the Date

  eval {
    $date_string = $date->value($datestring);
    $date_string = $date->value('now');
    $date_string = $date->value('');
    $date_string = $date->value(undef);
    $date_string = $date->value($year, $month, $day,
				$hour, $min, $sec);
    $date_string = $date->value(localtime);
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the value of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

The arguments are as described above in L<"Constructor -- Create a New
DateTime Object">.

=cut

sub value {
  (@_ > 0) or croak('Usage: $obj->value([$datestring | ' .
		    '$year, $month, $day, $hour, $min, $sec])');
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### month name to number map ###
  my %month_to_num = (
		      'jan' => '01',
		      'feb' => '02',
		      'mar' => '03',
		      'apr' => '04',
		      'may' => '05',
		      'jun' => '06',
		      'jul' => '07',
		      'aug' => '08',
		      'sep' => '09',
		      'oct' => '10',
		      'nov' => '11',
		      'dec' => '12',
		     );

  ### common patterns of parts of the date string ###
  my $num4 = '\d{1,4}';
  my $num2 = '\d{1,2}';

  ### set it ###
  if (@_ == 1) {  ### one argument passed ###
    my $arg = shift;
    if (!defined($arg) || $arg eq '') {
      $this->year(undef);   $this->month(undef);    $this->day(undef);
      $this->hours(undef);  $this->minutes(undef);  $this->seconds(undef);
    } elsif ($arg eq 'now') {
      $this->value(localtime);
    } elsif ($arg =~ /
                      ^($num4)[-\/]($num2)[-\/]($num2)
                      \s+
                      ($num2):($num2):($num2)$
		     /x) {
      $this->year($1);   $this->month($2);    $this->day($3);
      $this->hours($4);  $this->minutes($5);  $this->seconds($6);
    } elsif ($arg =~ /^($num2)-(\w{3})-($num4)$/) {
      $this->year($3);  $this->month($month_to_num{lc $2});  $this->day($1);
      $this->hours(undef);  $this->minutes(undef);  $this->seconds(undef);
    } elsif ($arg =~ /^$num4$/) {
      $this->year($arg);    $this->month(shift);    $this->day(shift);
      $this->hours(shift);  $this->minutes(shift);  $this->seconds(shift);
    } else {
      croak "date ($arg) does not match any of the valid formats";
    }
  } elsif (@_ > 1 && @_ < 7) {  ### 2..6 arguments passed ###
      $this->year(shift);   $this->month(shift);    $this->day(shift);
      $this->hours(shift);  $this->minutes(shift);  $this->seconds(shift);
    } elsif (@_ > 6 && @_ < 10) {  ### 7..9 arguments passed ###
      $this->seconds(shift);  $this->minutes(shift);  $this->hours(shift);
      $this->day(shift);      $this->month(1+shift);  $this->year(1900+shift);
  } elsif (@_ != 0) {  ### > 9 arguments passed ###
    croak sprintf("Too many arguments (%s) passed", scalar @_);
  }

  ### return it ###
  my $year = $this->year();
  my $month = $this->month();
  my $day = $this->day();
  my $hours = $this->hours();
  my $minutes = $this->minutes();
  my $seconds = $this->seconds();
  if (!defined($year) && !defined($month) && !defined($day) &&
      !defined($hours) && !defined($minutes) && !defined($seconds)) {
    undef;
  } else {
    sprintf("%04s-%02s-%02s %02s:%02s:%02s",
	    $year || '', $month || '', $day || '',
	    $hours || '', $minutes || '', $seconds || '');
  }
}

########################################################################
# get_compare_op
########################################################################

=head2 get_compare_op -- Returns the Comparison Operator for DateTime

  $cmp_op = $date->get_compare_op();

Returns the comparison operator for the DateTime class which is 'cmp'.
This method does not throw execeptions.

Parameters:

=over 4

=item None

=back

=cut

sub get_compare_op {
  (@_ == 1) or croak 'Usage: $obj->get_compare_op()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  'cmp';  ### string comparison operator ###
}

########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
########################################################################

########################################################################
# year
########################################################################

=head2 year -- Accesses the Year of the Date

  eval {
    ### set the year ###
    $date->year($new_year);

    ### get the year ###
    $year = $date->year();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the year of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$year>

A 4-digit year.  The year must be >= 0 and <= 9999.  If it is undef
then the year will be set to undef.

=back

=cut

sub year {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->year([$year])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $year = shift;
    $year = undef if defined($year) && $year eq '';
    if (defined $year) {
      croak "year ($year) must be between 0 and 9999"
	if $year < 0 || $year > 9999;
      $this->{Data}->{Year} = sprintf("%04d", $year);
    } else {
      $this->{Data}->{Year} = $year;
    }
  }

  ### return it ###
  $this->{Data}->{Year};
}

########################################################################
# month
########################################################################

=head2 month -- Accesses the Month of the Date

  eval {
    ### set the month ###
    $date->month($new_month);

    ### get the month ###
    $month = $date->month();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the month of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$month>

The month must be >= 1 and <= 12.  If it is undef then the month will
be set to undef.

=back

=cut

sub month {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->month([$month])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $month = shift;
    $month = undef if defined($month) && $month eq '';
    if (defined $month) {
      croak "month ($month) must be between 1 and 12"
	if $month < 1 || $month > 12;
      $this->{Data}->{Month} = sprintf("%02d", $month);
    } else {
      $this->{Data}->{Month} = $month;
    }
  }

  ### return it ###
  $this->{Data}->{Month};
}

########################################################################
# day
########################################################################

=head2 day -- Accesses the Day of the Date

  eval {
    ### set the day ###
    $date->day($new_day);

    ### get the day ###
    $day = $date->day();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the day of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$day>

The day must be >= 1 and <= 31.  If it is undef then the day will
be set to undef.

=back

=cut

sub day {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->day([$day])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $day = shift;
    $day = undef if defined($day) && $day eq '';
    if (defined $day) {
      croak "day ($day) must be between 1 and 31"
	if $day < 1 || $day > 31;
      $this->{Data}->{Day} = sprintf("%02d", $day);
    } else {
      $this->{Data}->{Day} = $day;
    }
  }

  ### return it ###
  $this->{Data}->{Day};
}

########################################################################
# hours
########################################################################

=head2 hours -- Accesses the Hours of the Date

  eval {
    ### set the hours ###
    $date->hours($new_hours);

    ### get the hours ###
    $hours = $date->hours();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the hours of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$hours>

The hours must be >= 0 and <= 23.  If it is undef then the hours will
be set to undef.

=back

=cut

sub hours {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->hours([$hours])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $hours = shift;
    $hours = undef if defined($hours) && $hours eq '';
    if (defined $hours) {
      croak "hours ($hours) must be between 0 and 23"
	if $hours < 0 || $hours > 23;
      $this->{Data}->{Hours} = sprintf("%02d", $hours);
    } else {
      $this->{Data}->{Hours} = $hours;
    }
  }

  ### return it ###
  $this->{Data}->{Hours};
}

sub hour {
  my $this = shift;

  $this->hours(@_);
}

########################################################################
# minutes
########################################################################

=head2 minutes -- Accesses the Minutes of the Date

  eval {
    ### set the minutes ###
    $date->minutes($new_minutes);

    ### get the minutes ###
    $minutes = $date->minutes();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the minutes of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$minutes>

The minutes must be >= 1 and <= 59.  If it is undef then the minutes will
be set to undef.

=back

=cut

sub minutes {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->minutes([$minutes])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $minutes = shift;
    $minutes = undef if defined($minutes) && $minutes eq '';
    if (defined $minutes) {
      croak "minutes ($minutes) must be between 0 and 59"
	if $minutes < 0 || $minutes > 59;
      $this->{Data}->{Minutes} = sprintf("%02d", $minutes);
    } else {
      $this->{Data}->{Minutes} = $minutes;
    }
  }

  ### return it ###
  $this->{Data}->{Minutes};
}

sub minute {
  my $this = shift;

  $this->minutes(@_);
}

########################################################################
# seconds
########################################################################

=head2 seconds -- Accesses the Seconds of the Date

  eval {
    ### set the seconds ###
    $date->seconds($new_seconds);

    ### get the seconds ###
    $seconds = $date->seconds();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the seconds of the DateTime object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$seconds>

The seconds must be >= 0 and <= 59.  If it is undef then the seconds will
be set to undef.

=back

=cut

sub seconds {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->seconds([$seconds])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  if (@_) {
    my $seconds = shift;
    $seconds = undef if defined($seconds) && $seconds eq '';
    if (defined $seconds) {
      croak "seconds ($seconds) must be between 0 and 59"
	if $seconds < 0 || $seconds > 59;
      $this->{Data}->{Seconds} = sprintf("%02d", $seconds);
    } else {
      $this->{Data}->{Seconds} = $seconds;
    }
  }

  ### return it ###
  $this->{Data}->{Seconds};
}

sub second {
  my $this = shift;

  $this->seconds(@_);
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::DataType::Char>,
L<Persistent::DataType::Number>, L<Persistent::DataType::String>,
L<Persistent::DataType::VarChar>

=head1 BUGS

This software is definitely a work in progress.  So if you find any
bugs please email them to me with a subject of 'Persistent Bug' at:

  winters@bigsnow.org

And you know, include the regular stuff, OS, Perl version, snippet of
code, etc.

=head1 AUTHORS

  David Winters <winters@bigsnow.org>

=head1 COPYRIGHT

Copyright (c) 1998-2000 David Winters.  All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
