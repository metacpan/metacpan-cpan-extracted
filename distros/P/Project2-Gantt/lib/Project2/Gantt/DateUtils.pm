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
package Project2::Gantt::DateUtils;

use Mojo::Base -strict,-signatures;

use Exporter ();
use vars qw[@EXPORT_OK %EXPORT_TAGS @ISA];

@ISA = qw[Exporter];

@EXPORT_OK = qw[
	hourBegin
	hourEnd
	dayBegin
	dayEnd
	monthBegin
	monthEnd
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
);

##########################################################################
#
#	Function: monthsBetween(date1, date2)
#
#	Purpose: Calculates the number of months spanned by two dates.
#		This is inclusive of the rest of the months.
#
##########################################################################
sub monthsBetween($date1, $date2, $log = Mojo::Log->new) {
    # Peter Weatherdon Jan 25, 2005
    # Used new monthEarly and monthLate functions instead of monthBegin and 
    # monthEnd because Class::Date has some problems calculating date
    # differences at the boundaries.  For example if date1=2005-01-31 23:59:59
    # and date2=2005-12-01 01:00:00 then the difference in months is 
    # 9.95640678332187 instead of the expected 10 plus a bit.
	$date1	= monthEarly($date1, $log);
	$date2	= monthLate($date2, $log);
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
sub daysBetween($date1, $date2, $log = Mojo::Log->new) {
	$date1	= dayEnd($date1, $log);
	$date2	= dayBegin($date2, $log);
	my $rough = int(($date2-$date1)->days);
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
sub hoursBetween($date1, $date2, $log = Mojo::Log->new) {
	$date1	= hourEnd($date1,$log);
	$date2	= hourBegin($date2,$log);
	my $rough = int(($date2-$date1)->hours);
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
sub hourBegin($date, $log = Mojo::Log->new) {
	$log->debug("#"x40);
	$log->debug("hourBegin date=$date");
	$date -= ($date->min() - 1)."m" if $date->min > 0;
	$date -= ($date->sec() - 1)."s" if $date->sec > 0;
	$log->debug("hourBegin date=$date");
	$log->debug("-"x40);
	return $date;
}

##########################################################################
#
#	Function: hourEnd(date)
#
#	Purpose: Returns the date object, reset to the end of the hour.
#
##########################################################################
sub hourEnd($date, $log = Mojo::Log->new){
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
sub dayBegin($date, $log =  Mojo::Log->new) {
	$date	-= ($date->hour() - 1)."h" if $date->hour > 0;
	$date	= hourBegin($date, $log);
	return $date;
}

##########################################################################
#
#	Function: dayEnd(date)
#
#	Purpose: Returns the date object, reset to the end of the day.
#
##########################################################################
sub dayEnd($date, $log = Mojo::Log->new) {
	$date	+= (23 - $date->hour)."h" if $date->hour < 23;
	$date	= hourEnd($date, $log);
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
sub monthBegin($date, $log = Mojo::Log->new) {
	$date	= $date->month_begin();
	$date	= dayBegin($date, $log);
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
sub monthEnd($date, $log = Mojo::Log->new) {
	$date	= $date->month_end();
	$date	= dayEnd($date, $log);
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
sub monthEarly($date, $log = Mojo::Log->new) {
    return Time::Piece->strptime($date->year . "-" . $date->month . "-" . "05");
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
sub monthLate($date, $log = Mojo::Log->new) {
    return Time::Piece->strptime($date->year . "-" . $date->month . "-" . "25");
}

1;
