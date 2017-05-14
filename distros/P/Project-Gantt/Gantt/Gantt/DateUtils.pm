##########################################################################
#
#	File:	Project/Gantt/DateUtils.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: Collection of utility functions for manipulating
#		Class::Date objects. Contains functions for getting the
#		number of hours/days/months between two dates, getting
#		the end and beginning of hours/days/months, and looking
#		up the string name of a day of the week or month.
#
#	Client: CPAN
#
#	CVS: $Id: DateUtils.pm,v 1.4 2004/08/03 17:56:52 awestholm Exp $
#
##########################################################################
package Project::Gantt::DateUtils;
use strict;
use warnings;
use Exporter ();
use vars qw[@EXPORT_OK %EXPORT_TAGS @ISA];

@ISA	= qw[Exporter];

@EXPORT_OK = qw[hourBegin
		hourEnd
		dayBegin
		dayEnd
		monthBegin
		monthEnd
		getMonth 
		getDay
		monthsBetween
		hoursBetween
		daysBetween
	];

%EXPORT_TAGS = (
	compare		=>	[qw(
				monthsBetween
				daysBetween
				hoursBetween)],
	round		=>	[qw(
				hourEnd
				hourBegin
				dayEnd
				dayBegin
				monthEnd
				monthBegin)],
	lookup		=>	[qw(
				getDay
				getMonth)] );

##########################################################################
#
#	Function: monthsBetween(date1, date2)
#
#	Purpose: Calculates the number of months spanned by two dates.
#		This is inclusive of the rest of the months.
#
##########################################################################
sub monthsBetween {
	my $date1 = shift;
	my $date2 = shift;

    # Peter Weatherdon Jan 25, 2005
    # Used new monthEarly and monthLate functions instead of monthBegin and 
    # monthEnd because Class::Date has some problems calculating date
    # differences at the boundaries.  For example if date1=2005-01-31 23:59:59
    # and date2=2005-12-01 01:00:00 then the difference in months is 
    # 9.95640678332187 instead of the expected 10 plus a bit.
	$date1	= monthEarly($date1);
	$date2	= monthLate($date2);
	my $rough = ($date2-$date1)->month;
	return int($rough)+1;
}

##########################################################################
#
#	Function: daysBetween(date1, date2)
#
#	Purpose: Inclusive calculation of the number of days between two
#		Class::Date objects.
#
##########################################################################
sub daysBetween {
	my $date1 = shift;
	my $date2 = shift;
	$date1	= dayEnd($date1);
	$date2	= dayBegin($date2);
	my $rough = int(($date2-$date1)->day);
	return $rough+2;
}

##########################################################################
#
#	Function: hoursBetween(date1, date2)
#
#	Purpose: Inclusive calculation of the number of hours between two
#		Class::Date objects.
#
##########################################################################
sub hoursBetween {
	my $date1 = shift;
	my $date2 = shift;
	$date1	= hourEnd($date1);
	$date2	= hourBegin($date2);
	my $rough = int(($date2-$date1)->hour);
	return $rough+2;
}

##########################################################################
#
#	Function: hourBegin(date)
#
#	Purpose: Returns the date object, reset to the beginning of the
#		hour.
#
##########################################################################
sub hourBegin {
	my $date = shift;
	$date	-= ($date->min() - 1)."m" if $date->min > 0;
	$date	-= ($date->sec() - 1)."s" if $date->sec > 0;
	return $date;
}

##########################################################################
#
#	Function: hourEnd(date)
#
#	Purpose: Returns the date object, reset to the end of the hour.
#
##########################################################################
sub hourEnd {
	my $date = shift;
	$date	+= (59 - $date->min)."m" if $date->min < 59;
	$date	+= (59 - $date->sec)."s" if $date->sec < 59;
	return $date;
}

##########################################################################
#
#	Function: dayBegin(date)
#
#	Purpose: Returns the date object, reset to the beginning of the
#		day.
#
##########################################################################
sub dayBegin {
	my $date = shift;
	$date	-= ($date->hour() - 1)."h" if $date->hour > 0;
	$date	= hourBegin($date);
	return $date;
}

##########################################################################
#
#	Function: dayEnd(date)
#
#	Purpose: Returns the date object, reset to the end of the day.
#
##########################################################################
sub dayEnd {
	my $date = shift;
	$date	+= (23 - $date->hour)."h" if $date->hour < 23;
	$date	= hourEnd($date);
	return $date;
}

##########################################################################
#
#	Function: monthBegin(date)
#
#	Purpose: Returns the date, reset to the beginning of the month.
#		Differs from similar function provided by Class::Date by
#		going to the very beginning of the month, and not just
#		the first day along with whatever hour was origionally
#		used.
#
##########################################################################
sub monthBegin {
	my $date= shift;
	$date	= $date->month_begin();
	$date	= dayBegin($date);
	return $date;
}

##########################################################################
#
#	Function: monthEnd(date)
#
#	Purpose: Returns the date, reset to the end of the month. Similar
#		Differs from the function provided by Class::Date in a
#		similar manner to the function above.
#
##########################################################################
sub monthEnd {
	my $date= shift;
	$date	= $date->month_end();
	$date	= dayEnd($date);
	return $date;
}


##########################################################################
#
#   Function: monthEarly(date)
#
#   Author: Peter Weatherdon
#
#   Purpose: Returns the date, reset to the 5th of the month. 
#
##########################################################################
sub monthEarly {
    my $date = shift;
    return new Class::Date ($date->year . "-" . $date->month . "-" . "05");
}


##########################################################################
#
#   Function: monthLate(date)
#
#   Author: Peter Weatherdon
#
#   Purpose: Returns the date, reset to the 25th of the month. 
#
##########################################################################
sub monthLate {
    my $date = shift;
    return new Class::Date ($date->year . "-" . $date->month . "-" . "25");
}

##########################################################################
#
#	Function: getDay(date)
#
#	Purpose: Returns the string representation of the day of the week
#		for the date passed in.
#
##########################################################################
sub getDay {
	my $day		= shift;
	my @days;
	$days[1]	= 'Sunday';
	$days[2]	= 'Monday';
	$days[3]	= 'Tuesday';
	$days[4]	= 'Wednesday';
	$days[5]	= 'Thursday';
	$days[6]	= 'Friday';
	$days[7]	= 'Saturday';
	return $days[$day];
}

##########################################################################
#
#	Function: getMonth(date)
#
#	Purpose: Returns the string representation of the month for the
#		date passed in.
#
##########################################################################
sub getMonth {
	my $month	= shift;
	my @months;
	$months[1]	= 'January';
	$months[2]	= 'February';
	$months[3]	= 'March';
	$months[4]	= 'April';
	$months[5]	= 'May';
	$months[6]	= 'June';
	$months[7]	= 'July';
	$months[8]	= 'August';
	$months[9]	= 'September';
	$months[10]	= 'October';
	$months[11]	= 'November';
	$months[12]	= 'December';
	return $months[$month];
}

1;
