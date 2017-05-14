##########################################################################
#
#	File:	Project/Gantt/GanttHeader.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: This object paints a calendar header on the canvas. It is
#		also responsible for drawing the 'swim lanes' used to
#		visually locate each task on the calendar.
#
#	Client:	CPAN
#
#	CVS: $Id: GanttHeader.pm,v 1.6 2004/08/03 17:56:52 awestholm Exp $
#
##########################################################################
package Project::Gantt::GanttHeader;
use strict;
use warnings;
use Project::Gantt::DateUtils qw[:round :lookup];
use Project::Gantt::TextUtils;
use Project::Gantt::Globals;

##########################################################################
#
#	Method:	new(%opts)
#
#	Purpose: Constructor. Takes the following parameters: canvas,
#		the root Project::Gantt object and the skin object.
#
##########################################################################
sub new {
	my $cls	= shift;
	my %ops	= @_;
	die "Improper construction of GanttHeader!" if(not($ops{canvas} and $ops{root}));
	return bless {
		canvas		=>	$ops{canvas},
		title		=>	$ops{root}->getDescription(),
		startDate	=>	$ops{root}->getStartDate()->clone(),
		endDate		=>	$ops{root}->getEndDate(),
		skin		=>	$ops{skin},
		beginY		=>	30,
		beginX		=>	205,
	}, $cls;
}

##########################################################################
#
#	Method:	display(mode)
#
#	Purpose: Selects and calls the apropriate header painting method,
#		and if the skin wishes to display the title, the method
#		responsible for doing that is called.
#
##########################################################################
sub display {
	my $me	= shift;
	my $mode= shift;
	if($mode eq 'hours'){
		$me->_writeHeaderHours();
	}elsif($mode eq 'months'){
		$me->_writeHeaderMonths();
	}else{
		$me->_writeHeaderDays();
	}
	if($me->{skin}->doTitle()){
		$me->_writeTitle();
	}
}

##########################################################################
#
#	Method:	_writeHeaderDays()
#
#	Purpose: Iterates over the the span from start to end of the chart
#		by increments of one day. For each day, a square is
#		written to the top of the chart containing the day's
#		number within the month, and the name of the month is
#		written above these squares. Also, swimlanes are put in
#		after each square if the skin calls for it.
#
##########################################################################
sub _writeHeaderDays {
	my $me		= shift;
	my $start	= $me->{startDate};
	my $end		= $me->{endDate};
	my @monthsWritn	= ();
	my $yval	= $me->{beginY};
	my $xval	= $me->{beginX};
	$start		= dayBegin($start);

	while($start <= $end){
		# if haven't already written the name of this month out
		if(not $monthsWritn[$start->month]){
			# if more than 15 days left in month, write name of month above day listings
			if((($start->month_end() - $start) >= "15D") and (($end-$start)>="15D")){
				$me->_writeText(
					getMonth($start->month),
					$xval,
					12);
				$monthsWritn[$start->month] = 1;
			}
		}
		# write each day
		$me->_writeRectangle(
			$DAYSIZE,
			$start->day,
			$xval,
			$yval);
		$me->_writeSwimLane($xval, $yval) if $me->{skin}->doSwimLanes();
		$start	+= "1D";
		$xval	+= $DAYSIZE;
	}
}

##########################################################################
#
#	Method:	_writeHeaderMonths()
#
#	Purpose: For each month between the start and end of the chart,
#		inclusively, a rectangle featuing that month's name is
#		drawn at the top of the chart. Also, swimlanes are
#		installed after each month if the skin dictates.
#
##########################################################################
sub _writeHeaderMonths {
	my $me		= shift;
	my $start	= $me->{startDate};
	my $end		= $me->{endDate};
	my @yearsWritn	= ();
	my $yval	= $me->{beginY};
	my $xval	= $me->{beginX};
	# transform start date to absolute beginning of month,
	# so that $start+"1M" won't ever be bigger than $end
	# before it should be
	$start		= monthBegin($start);

	while($start <= $end){
		# if haven't written this year
		if((not $yearsWritn[$start->year]) and (($end->month-$start->month)>1)){
			# if year has more than one month on chart, display year above months
			if((getMonth($start->month) ne 'December') and (getMonth($end->month) ne 'January')){
				$me->_writeText(
					$start->year,
					$xval,
					12);
				$yearsWritn[$start->year] = 1;
			}
		}
		# write each month
		$me->_writeRectangle(
			$MONTHSIZE,
			getMonth($start->month),
			$xval,
			$yval);
		$me->_writeSwimLane($xval, $yval) if $me->{skin}->doSwimLanes();
		$start	+= "1M";
		$xval	+= $MONTHSIZE;
	}
}

##########################################################################
#
#	Method:	_writeHeaderHours()
#
#	Purpose: Draws a box for each hour between the beginning and end
#		of the chart, and optionally, a swimlane for each hour.
#
##########################################################################
sub _writeHeaderHours {
	my $me		= shift;
	my $start	= $me->{startDate};
	my $end		= $me->{endDate};
	my @daysWritn	= ();
	my $yval	= $me->{beginY};
	my $xval	= $me->{beginX};
	$start		= hourBegin($start);

	while($start <= $end){
		# if day not already written
		if((not $daysWritn[$start->day.$start->month]) and (($end->hour-$start->hour)>5)){
			# if day has more than 6 hours on chart, list day of week
			if(($start->hour <= 18) and ($end->hour >= 6)){
				$me->_writeText(
					getDay($start->wday),
					$xval,
					12);
				$daysWritn[$start->day.$start->month] = 1;
			}
		}
		# write each hour
		$me->_writeRectangle(
			$DAYSIZE,
			$start->hour,
			$xval,
			$yval);
		$me->_writeSwimLane($xval, $yval) if $me->{skin}->doSwimLanes();
		$start	+= "1h";
		$xval	+= $DAYSIZE;
	}
}

##########################################################################
#
#	Method:	_wrietRectangle(width, text, xval, yval)
#
#	Purpose: Method used by the _writeHeader* methods to paint the
#		square/rectangle representing each interval of time.
#
##########################################################################
sub _writeRectangle {
	my $me		= shift;
	my $width	= shift;
	my $text	= shift;
	my $xval	= shift;
	my $yval	= shift;
	my $height	= 17;
	my $oxval	= $xval + $width;
	my $oyval	= $yval - $height;
	my $canvas	= $me->{canvas};
	# draw box and inscribe text for a time unit above chart
	$canvas->Draw(
		fill		=>	$me->{skin}->secondaryFill(),
		stroke		=>	$me->{skin}->infoStroke(),
		primitive	=>	'rectangle',
		points		=>	"${xval}, $yval ${oxval}, $oyval");
	$canvas->Annotate(
		text		=>	$text,
		font		=>	$me->{skin}->font(),
		fill		=>	$me->{skin}->primaryText(),
		pointsize	=>	10,
		x		=>	$xval + 2,
		y		=>	$yval - 5);
}

##########################################################################
#
#	Method:	_writeText(text, xval, yval)
#
#	Purpose: Method used to write month name/ year number/ day name
#		above calendar header.
#
##########################################################################
sub _writeText {
	my $me		= shift;
	my $text	= shift;
	my $xval	= shift;
	my $yval	= shift;
	my $canvas	= $me->{canvas};
	# used to write name of month/day/year above time units
	$canvas->Annotate(
		text		=>	$text,
		font		=>	$me->{skin}->font(),
		fill		=>	$me->{skin}->primaryText(),
		pointsize	=>	10,
		x		=>	$xval,
		y		=>	$yval);
}

##########################################################################
#
#	Method:	_writeTitle()
#
#	Purpose: Truncates the title if necesary and draws it to the
#		canvas.
#
##########################################################################
sub _writeTitle {
	my $me		= shift;
	my $title	= truncateStr($me->{title},200);
	my $xval	= 1;
	my $yval	= 12;
	$me->_writeText($title, $xval, $yval);
}

##########################################################################
#
#	Method: _writeSwimLane(xval, yval)
#
#	Purpose: Draws a vertical line on the chart seperating the units
#		of time.
#
##########################################################################
sub _writeSwimLane {
	my $me		= shift;
	my $xval	= shift;
	my $yval	= shift;
	my $canvas	= $me->{canvas};
	my $endY	= $canvas->Get('height')-3;
	$canvas->Draw(
		primitive	=>	'line',
		stroke		=>	$me->{skin}->secondaryFill(),
		points		=>	"${xval}, ".($yval+1)." ${xval}, $endY");
}

1;
