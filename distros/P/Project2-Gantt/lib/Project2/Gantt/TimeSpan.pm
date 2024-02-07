package Project2::Gantt::TimeSpan;

use Mojo::Base -base,-signatures;

use Project2::Gantt::Globals;

use Mojo::Log;

our $DATE = '2024-02-05'; # DATE
our $VERSION = '0.011';

has task    => undef;
has canvas  => undef;
has skin    => undef;
has rootStr => undef;

has log     => sub { Mojo::Log->new };

sub new {
	my $self = shift->SUPER::new(@_);
	die "Must provide proper args to TimeSpan!" if not defined $self->task or not defined $self->rootStr;
	return $self;
}

sub write($self, $mode, $height, $start = undef, $end =  undef) {
	$self->_writeBar($mode, $height, $start, $end);
}

sub _writeBar($self, $mode, $height, $start = undef, $end = undef) {
	my $task        = $self->task;
	my $rootStart   = $self->rootStr;
	my $taskStart   = $task->start;
	my $taskEnd     = $task->end;
	my $startX      = $self->skin->spanInfoWidth;

	my $past_task   = undef;
	my $future_task = undef;

	if( defined $start and $taskStart < $start ) {
		$taskStart = $start;
		$past_task = 1;
	}

	if ( defined $end and $taskEnd > $end) {
		$taskEnd = $end;
		$future_task = 1;
	}

	my $dif       = $taskStart-$rootStart;

	# calculate starting X coordinate based on number of units away from start it is
	if($mode eq 'hours'){
		$startX += $dif->hours * $DAYSIZE;
		$startX += (($rootStart->min / 59) * $DAYSIZE);
	}elsif($mode eq 'months'){
		$startX	+= $self->_getMonthPixels($rootStart->month_begin, $taskStart);
	}else{
		$startX += $dif->days * $DAYSIZE;
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
		$endX	+= $edif->hours * $DAYSIZE;
		$range	= $edif->hours;
	}elsif($mode eq 'months'){
		my $tmp	= $self->_getMonthPixels($taskStart, $taskEnd);
		$endX	+= $tmp;
		$range	= $tmp / $DAYSIZE;
	}else{
		$endX	+= $edif->days * $DAYSIZE;
		$range	= $edif->days;
	}
	if($startX == $endX){
		die "Incorrect date range!";
	}
	
	$self->_drawSubProj($startX, $height, $endX, $range, $past_task, $future_task) if $task->isa("Project2::Gantt");
	$self->_drawTask($startX, $height, $endX, $range, $task->color, $past_task, $future_task) if $task->isa("Project2::Gantt::Task");
}

sub _getMonthPixels($self, $birth, $death) {
	my $pixelsPerYr	= 12 * 60;
	my $secsInYear	= (((60*60)*24)*365);
	my $secsInSpan	= ($death - $birth)->sec;
	my $percentage	= $secsInSpan / $secsInYear;
	return $percentage * $pixelsPerYr;
}

sub _drawTask($self, $startX, $startY, $endX, $range, $color = undef, $past_task = undef, $future_task =  undef) {
	my $log = $self->log;
	$color  = $self->{skin}->itemFill if not defined $color;

	$log->debug("_drawTask $startX, $startY, $endX, $range, $color");

	my $canvas = $self->{canvas};

	if ( $past_task ) {
		$canvas->line(
			color => 'red',
			x1    => $self->skin->spanInfoWidth,
			x2    => $self->skin->spanInfoWidth,
			y1    => $startY,
			y2    => $startY + 17,
			aa    => 1,
			endp  => 1
		);
		return;
	}

	if ( $future_task ) {
		$canvas->line(
			color => 'red',
			x1    => $canvas->getheight - 16,
			x2    => $canvas->getheight - 16,
			y1    => $startY,
			y2    => $startY + 17,
			aa    => 1,
			endp  => 1
		);
		return;
	}


	my $leadY  = $startY + 8.5;
	my $bottom = $startY + 13.5;
	$startY   += 3.5;
	my $leadX  = $startX + 7.5;
	my $trailX = $endX - 7.5;

	# if has space for full diamond
	if($range >= 1){
		# $canvas->Draw(
		# 	fill		=>	$me->{skin}->itemFill(),
		# 	stroke		=>	$me->{skin}->itemFill(),
		# 	primitive	=>	'polygon',
		# 	points		=>	"${startX}, $leadY ${leadX}, $bottom ${leadX}, $startY");
		$log->debug("_drawTask polygon 1 [$startX,$leadX],[$leadX,$bottom],[$leadX,$startY]");
		$canvas->polygon(
			points =>[[$startX,$leadY],[$leadX,$bottom],[$leadX,$startY]],
			fill => { solid=> $color, combine => 'normal'});
		# $canvas->Draw(
		# 	fill		=>	$me->{skin}->itemFill(),
		# 	stroke		=>	$me->{skin}->itemFill(),
		# 	primitive	=>	'polygon',
		# 	points		=>	"${trailX}, $bottom ${trailX}, $startY ${endX}, $leadY");
		$log->debug("_drawTask polygon 2 [$trailX,$bottom],[$trailX,$startY],[$endX,$leadY]");

		$canvas->polygon(
			points =>[[$trailX,$bottom],[$trailX,$startY],[$endX,$leadY]],
			fill => { solid => $color, combine => 'normal' }
		);
		# if space between diamond edges, fill in
		if($leadX != $trailX){
			# $canvas->Draw(
			# 	fill		=>	$me->{skin}->itemFill(),
			# 	stroke		=>	$me->{skin}->itemFill(),
			# 	primitive	=>	'rectangle',
			# 	points		=>	"${leadX}, $startY ${trailX}, $bottom");
			$canvas->box(
				color  => $color,
				xmin   => $leadX,
				ymin   => $startY,
				xmax   => $trailX,
				ymax   => $bottom,
				filled => 1
			);
		}
	# not enough space for full diamond, use rectangle
	}else{
		# $canvas->Draw(
		# 	fill		=>	$me->{skin}->itemFill(),
		# 	stroke		=>	$me->{skin}->itemFill(),
		# 	primitive	=>	'rectangle',
		# 	points		=>	"${startX}, $startY ${endX}, $bottom");
		$canvas->box(
			color  => $color,
			xmin   => $startX,
			ymin   => $startY,
			xmax   => $endX,
			ymax   => $bottom,
			filled => 1
		);
	}
}

sub _drawSubProj($self, $startX, $startY, $endX, $range, $past_task = undef, $future_task =  undef) {
	my $log    = $self->log;
	my $canvas = $self->{canvas};

	if ( $past_task ) {
		$canvas->line(
			color => 'red',
			x1    => $self->skin->spanInfoWidth,
			x2    => $self->skin->spanInfoWidth,
			y1    => $startY,
			y2    => $startY + 17,
			aa    => 1,
			endp  => 1
		);
		return;
	}

	if ( $future_task ) {
		$canvas->line(
			color => 'red',
			x1    => $canvas->getheight - 16,
			x2    => $canvas->getheight - 16,
			y1    => $startY,
			y2    => $startY + 17,
			aa    => 1,
			endp  => 1
		);
		return;
	}

	my $edgeTop  = $startY + 7;
	my $edgeBot  = $startY + 17;
	my $innerBot = $startY + 10;
	my $polyX    = $startX + 7.5;
	my $endPolyX = $endX   - 7.5;

	$log->debug("_drawSubProj");


	$canvas->line(
		color => $self->skin->secondaryFill,
		x1    => 206,
		x2    => $canvas->getwidth - 16,
		y1    => $startY,
		y2    => $startY,
		aa    => 1,
		endp  => 1
	);

	#if enough space for full bracket
	if($range >= 1){
		$log->debug("_drawSubProj polygon 1 [$startX,$edgeBot],[$startX,$edgeTop],[$polyX,$startY],[$polyX,$innerBot]");
		$canvas->polygon(
			points =>[[$startX,$edgeBot],[$startX,$edgeTop],[$polyX,$startY],[$polyX,$innerBot]],
			color => 'grey',
			fill => { solid=>'grey', combine => 'normal'});
		$log->debug("_drawSubProj polygon 2 [$endPolyX,$innerBot],[$endPolyX,$startY],[$endX,$edgeTop],[$endX,$edgeBot]");
		$canvas->polygon(
			points =>[[$endPolyX,$innerBot],[$endPolyX,$startY],[$endX,$edgeTop],[$endX,$edgeBot]],
			color => 'red',
			fill => { solid=>'grey', combine => 'normal'});
		# if space between bracket ends, fill in
		if($polyX != $endPolyX){
			# $canvas->Draw(
			# 	fill		=>	$self->{skin}->containerFill(),
			# 	stroke		=>	$self->{skin}->containerStroke(),
			# 	primitive	=>	'rectangle',
			# 	points		=>	"${polyX}, $startY ${endPolyX}, $innerBot");
			$canvas->box(
				color  => 'grey',
				xmin   => $polyX,
				ymin   => $startY,
				xmax   => $endPolyX,
				ymax   => $innerBot,
				filled => 1,
			);
		}
	# not enough space for full bracket, use rectangle
	}else{
		$canvas->box(
			color => 'red',
			xmin =>$startX,
			ymin =>$startY,
			xmax =>$endX,
			ymax =>$edgeBot
		);
	}
}

1;
