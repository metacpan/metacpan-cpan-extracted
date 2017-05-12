##########################################################################
#
#	File:	Project/Gantt/TimeSpan.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: This class is a visual representation of a timespan on
#		a Gantt chart. It is used to display both sub-projects,
#		and the tasks they contain. 
#
#	Client:	CPAN
#
#	CVS: $Id: TimeSpan.pm,v 1.4 2004/08/03 17:56:52 awestholm Exp $
#
##########################################################################
package Project::Gantt::TimeSpan;
use strict;
use warnings;
use Project::Gantt::Globals;

##########################################################################
#
#	Method:	new(%opts)
#
#	Purpose: Constructor. Takes as parameters the Task or Gantt object
#		it is going to display, as well as the Class::Date object
#		representing the beginning of the chart. In addition, the
#		Image::Magick canvas is passed in, along with a skin object
#		to customize the colors of this TimeSpan.
#
##########################################################################
sub new {
	my $cls	= shift;
	my %ops	= @_;
	die "Must provide proper args to TimeSpan!" if(not($ops{task} and $ops{rootStr}));
	return bless {
		task	=>	$ops{task},
		rootStr	=>	$ops{rootStr},
		canvas	=>	$ops{canvas},
		skin	=>	$ops{skin},
		beginX	=>	205,
	}, $cls;
}

##########################################################################
#
#	Method:	Display(mode, height)
#
#	Purpose: Calls _writeBar passing its parameters along. Simply a
#		placeholder at this point, but exists incase some
#		preprocessing is necessary at a later date.
#
##########################################################################
sub display {
	my $me	= shift;
	my $mod	= shift;
	my $hgt	= shift;
	$me->_writeBar($mod, $hgt);
}

##########################################################################
#
#	Method:	_writeBar(mode, height)
#
#	Purpose: This method calculates the distance from the beginning of
#		the graph at which to begin drawing this TimeSpan, as well
#		as how many pixels in width it should be. It then calls
#		either _drawSubProj or _drawTask depending on whether
#		the task object passed to the constructor is a
#		Project::Gantt instance or a Project::Gantt::Task
#		instance.
#
##########################################################################
sub _writeBar {
	my $me		= shift;
	my $mode	= shift;
	my $height	= shift;
	my $tsk		= $me->{task};
	my $rootStart	= $me->{rootStr};
	my $taskStart	= $tsk->getStartDate();
	my $taskEnd	= $tsk->getEndDate();
	my $startX	= $me->{beginX};
	my $dif		= $taskStart-$rootStart;

	# calculate starting X coordinate based on number of units away from start it is
	if($mode eq 'hours'){
		$startX += $dif->hour * $DAYSIZE;
		$startX += (($rootStart->min / 59) * $DAYSIZE);
	}elsif($mode eq 'months'){
		$startX	+= $me->_getMonthPixels($rootStart->month_begin, $taskStart);
	}else{
		$startX += $dif->day * $DAYSIZE;
		$startX += (($rootStart->hour / 23) * $DAYSIZE);
	}
	my $endX	= $startX;
	my $edif	= $taskEnd-$taskStart;
	# range variable indicates whether or not space filled by this bar is less than 15 pixels or not
	# this is because 15 pixels are required for the diamond shape... if less than, a rectangle
	# is used
	my $range	= 0;

	# calculate ending X coordinate based on number of units within this bar
	if($mode eq 'hours'){
		$endX	+= $edif->hour * $DAYSIZE;
		$range	= $edif->hour;
	}elsif($mode eq 'months'){
		my $tmp	= $me->_getMonthPixels($taskStart, $taskEnd);
		$endX	+= $tmp;
		$range	= $tmp / $DAYSIZE;
	}else{
		$endX	+= $edif->day * $DAYSIZE;
		$range	= $edif->day;
	}
	if($startX == $endX){
		die "Incorrect date range!";
	}
	
	$me->_drawSubProj($startX, $height, $endX, $range) if $tsk->isa("Project::Gantt");
	$me->_drawTask($startX, $height, $endX, $range) if $tsk->isa("Project::Gantt::Task");
}

##########################################################################
#
#	Method:	_getMonthPixels(start, end)
#
#	Purpose: Given the start and end of a TimeSpan, as passed in, this
#		method approximately calculates the number of pixels
#		that it should take up on the Gantt chart. There are some
#		minor errors occasionally, as this calculation is based on
#		the number of seconds in the task divided by the number of
#		seconds in the year. Since not every month has the same
#		number of seconds, minor miscalculations will occur.
#
##########################################################################
sub _getMonthPixels {
	my $me		= shift;
	my $birth	= shift;
	my $death	= shift;
	my $pixelsPerYr	= 12 * 60;
	my $secsInYear	= (((60*60)*24)*365);
	my $secsInSpan	= ($death - $birth)->sec;
	my $percentage	= $secsInSpan / $secsInYear;
	return $percentage * $pixelsPerYr;
}

##########################################################################
#
#	Method:	_drawTask(startX, startY, endX, range)
#
#	Purpose: Given the starting coordinates, and ending X coordinate
#		of a TimeSpan, uses Image::Magick to draw the span on the
#		chart using whatever Skin scheme is in effect. Range is
#		an indication of whether the span takes up more than
#		15 pixels or not. If so, the span is drawn as a diamond,
#		if not, as a rectangle.
#
##########################################################################
sub _drawTask {
	my $me		= shift;
	my $startX	= shift;
	my $startY	= shift;
	my $endX	= shift;
	my $range	= shift;
	my $canvas	= $me->{canvas};
	my $leadY	= $startY+8.5;
	my $bottom	= $startY+13.5;
	$startY		+= 3.5;
	my $leadX	= $startX+7.5;
	my $trailX	= $endX-7.5;
	# if has space for full diamond
	if($range >= 1){
		$canvas->Draw(
			fill		=>	$me->{skin}->itemFill(),
			stroke		=>	$me->{skin}->itemFill(),
			primitive	=>	'polygon',
			points		=>	"${startX}, $leadY ${leadX}, $bottom ${leadX}, $startY");
		$canvas->Draw(
			fill		=>	$me->{skin}->itemFill(),
			stroke		=>	$me->{skin}->itemFill(),
			primitive	=>	'polygon',
			points		=>	"${trailX}, $bottom ${trailX}, $startY ${endX}, $leadY");
		# if space between diamond edges, fill in
		if($leadX != $trailX){
			$canvas->Draw(
				fill		=>	$me->{skin}->itemFill(),
				stroke		=>	$me->{skin}->itemFill(),
				primitive	=>	'rectangle',
				points		=>	"${leadX}, $startY ${trailX}, $bottom");
		}
	# not enough space for full diamond, use rectangle
	}else{
		$canvas->Draw(
			fill		=>	$me->{skin}->itemFill(),
			stroke		=>	$me->{skin}->itemFill(),
			primitive	=>	'rectangle',
			points		=>	"${startX}, $startY ${endX}, $bottom");
	}
}

##########################################################################
#
#	Method:	_drawSubProj(startX, startY, endX, range)
#
#	Purpose: Same as above, except draws a bracket instead of a
#		diamond, indicating a containment relationship.
#
##########################################################################
sub _drawSubProj {
	my $me		= shift;
	my $startX	= shift;
	my $startY	= shift;
	my $endX	= shift;
	my $range	= shift;
	my $canvas	= $me->{canvas};
	my $edgeTop	= $startY+7;
	my $edgeBot	= $startY+17;
	my $innerBot	= $startY+10;
	my $polyX	= $startX+7.5;
	my $endPolyX	= $endX-7.5;
	#if enough space for full bracket
	if($range >= 1){
		$canvas->Draw(
			fill		=>	$me->{skin}->containerFill(),
			stroke		=>	$me->{skin}->containerStroke(),
			primitive	=>	'polygon',
			points		=>	"${startX}, $edgeBot ${startX}, $edgeTop ${polyX}, $startY ${polyX}, $innerBot");
		$canvas->Draw(
			fill		=>	$me->{skin}->containerFill(),
			stroke		=>	$me->{skin}->containerStroke(),
			primitive	=>	'polygon',
			points		=>	"${endPolyX}, $innerBot ${endPolyX}, $startY ${endX}, $edgeTop ${endX}, $edgeBot");
		# if space between bracket ends, fill in
		if($polyX != $endPolyX){
			$canvas->Draw(
				fill		=>	$me->{skin}->containerFill(),
				stroke		=>	$me->{skin}->containerStroke(),
				primitive	=>	'rectangle',
				points		=>	"${polyX}, $startY ${endPolyX}, $innerBot");
		}
	# not enough space for full bracket, use rectangle
	}else{
		$canvas->Draw(
			fill		=>	$me->{skin}->containerFill(),
			stroke		=>	$me->{skin}->containerStroke(),
			primitive	=>	'rectangle',
			points		=>	"${startX}, $startY ${endX}, $edgeBot");
	}
}

1;
