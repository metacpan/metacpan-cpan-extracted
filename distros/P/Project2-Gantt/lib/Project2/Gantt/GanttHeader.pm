package Project2::Gantt::GanttHeader;

use Mojo::Base -base,-signatures;

use Project2::Gantt::DateUtils qw[:round];
use Project2::Gantt::TextUtils;
use Project2::Gantt::Globals;

use Time::Seconds;

use Mojo::Log;

our $DATE = '2023-02-02'; # DATE
our $VERSION = '0.006';

has canvas => undef;
has title  => undef;
has start  => undef;
has end    => undef;
has skin   => undef;
has beginX => 205;
has beginY => 30;
has root   => undef;

has log    => sub { Mojo::Log->new };

use constant TITLE_SIZE => 200;

sub new {
	my $self = shift->SUPER::new(@_);
	$self->title($self->root->description);
	$self->start($self->root->start) if not defined $self->start;
	$self->end($self->root->end)     if not defined $self->end;
	return $self;
}

sub write($self, $mode = 'days', $start = undef, $end = undef) {
	if($mode eq 'hours'){
		$self->_writeHeaderHours($start, $end);
	}elsif($mode eq 'months'){
		$self->_writeHeaderMonths($start, $end);
	}else{
		$self->_writeHeaderDays($start, $end);
	}
	if($self->skin->doTitle){
		$self->_writeTitle();
	}
}

sub _writeHeaderDays($self, $start_date =  undef, $end_date =  undef) {
	my $log = $self->log;
	my $start	= $start_date // $self->start;
	my $end		= $end_date   // $self->end;
	my $yval	= $self->beginY;
	my $xval	= $self->beginX;
	$start		= dayBegin($start, $log);

	$log->debug("xval=$xval yval=$yval");

	my @monthsWritn	= ();

	while($start <= $end){
		$log->debug("_writeHeaderDays start=$start");
		$log->debug("_writeHeaderDays end=$end");
		$log->debug("_writeHeaderDays mon=" . $start->fullmonth);
		# if haven't already written the name of this month out
		if(not $monthsWritn[$start->mon.$start->year]){
			$log->debug("_writeHeaderDays Checking with we need to write the month name");
			# if more than 15 days left in month, write name of month above day listings
			$log->debug("_writeHeaderDays \$start->month_last_day " .$start->month_last_day);
			$log->debug("_writeHeaderDays \$start->mday " .$start->mday);
			if((($start->month_last_day - $start->mday) >= 15) and (($end-$start)>=15)) {
				$log->debug("_writeHeaderDays write fullmonth ... $xval 12");
				$self->_writeText(
					$start->fullmonth . " " . $start->year,
					$xval,
					12);
				$monthsWritn[$start->mon.$start->year] = 1;
			}
		}

		# write weekends
		$log->debug("_writeHeaderDays fullday=" . $start->fullday);
		if ($start->fullday eq 'Saturday' or $start->fullday eq 'Sunday') {
			$self->_writeWeekends(
				$xval,
				$yval,
			);
		}

		# write each day
		$self->_writeRectangle(
			$DAYSIZE,
			$start->mday,
			$xval,
			$yval
		) if not defined $end_date or $start < $end_date;

		$self->_writeSwimLane($xval, $yval) if $self->skin->doSwimLanes();
		$start	+= ONE_DAY;
		$xval	+= $DAYSIZE;
	}
	$self->_writeSwimLane($xval, $yval) if $self->skin->doSwimLanes();
}

sub _writeWeekends($self, $xval, $yval) {
	my $log = $self->log;
	$log->debug("_writeHeaderDays write weekend");
	my $canvas = $self->canvas;
	my $width = $DAYSIZE;
	my $height = $canvas->getheight - 2;
	my $oxval = $xval + $width;
	my $oyval = $height;
	$log->debug("_writeHeaderDays $xval $yval $oxval $oyval");
	$canvas->box(
		color  => $self->skin->secondaryFill,
		xmin   => $xval,
		ymin   => 14,
		xmax   => $oxval,
		ymax   => $oyval,
		filled => 1
	) or $log->debug("ERROR: " . $canvas->errstr);
}

sub _writeHeaderMonths($self) {
	my $log     = $self->log;
	my $start	= $self->start;
	my $end		= $self->end;
	my @yearsWritn	= ();
	my $yval	= $self->beginY;
	my $xval	= $self->beginX;
	# transform start date to absolute beginning of month,
	# so that $start+"1M" won't ever be bigger than $end
	# before it should be
	$start		= monthBegin($start, $log);

	while($start <= $end){
		# if haven't written this year
		if((not $yearsWritn[$start->year]) and (($end->month-$start->month)>1)){
			# if year has more than one month on chart, display year above months
			if((getMonth($start->month) ne 'December') and (getMonth($end->month) ne 'January')){
				$self->_writeText(
					$start->year,
					$xval,
					12);
				$yearsWritn[$start->year] = 1;
			}
		}
		# write each month
		$self->_writeRectangle(
			$MONTHSIZE,
			getMonth($start->month),
			$xval,
			$yval);
		$self->_writeSwimLane($xval, $yval) if $self->skin->doSwimLanes();
		$start	+= "1M";
		$xval	+= $MONTHSIZE;
	}
}

sub _writeHeaderHours($self, $start_hour =  undef, $end_hour =  undef) {
	my $log       = $self->log;
	my $start	  = $start_hour // $self->start;
	my $end		  = $end_hour   // $self->end;
	my @daysWritn = ();
	my $yval	  = $self->beginY;
	my $xval	  = $self->beginX;
	$start		  = hourBegin($start, $log);

	while($start <= $end){
		$log->debug("_writeHeaderHours start=$start");
		$log->debug("_writeHeaderHours end=$end");
		# if day not already written
		if((not $daysWritn[$start->mday.$start->mon]) and (($end->hour-$start->hour)>5)){
			# if day has more than 6 hours on chart, list day of week
			if(($start->hour <= 18) and ($end->hour >= 6)){
				$self->_writeText(
					$start->fullday,
					$xval,
					12);
				$daysWritn[$start->mday.$start->mon] = 1;
			}
		}
		# write each hour
		$self->_writeRectangle(
			$DAYSIZE,
			$start->hour,
			$xval,
			$yval);
		$self->_writeSwimLane($xval, $yval) if $self->skin->doSwimLanes();
		$start	+= ONE_HOUR;
		$xval	+= $DAYSIZE;
	}
}

sub _writeRectangle($self, $width, $text, $xval, $yval) {
	my $log     = $self->log;
	my $height	= 17;
	my $oxval	= $xval + $width;
	my $oyval	= $yval - $height;
	my $canvas	= $self->canvas;
	# draw box and inscribe text for a time unit above chart

	$log->debug("_writeRectangle $xval $yval $oxval $oyval");

	$canvas->box(
		color => $self->skin->secondaryFill,
		xmin  => $xval,
		ymin  => $yval,
		xmax  => $oxval,
		ymax  => $oyval
	) or $log->debug("ERROR: " . $canvas->errstr);

	$canvas->string(
		x      => $xval + 2,
		y      => $yval - 5,
		string => $text,
		font   => $self->skin->font,
		size   => 10,
		aa     => 1,
		color  => 'black'
	);
}

sub _writeText($self, $text, $xval, $yval) {
	my $log = $self->log;
	$log->debug("_writeText $text, $xval, $yval");
	$self->canvas->string(
		x => $xval,
		y => $yval,
		string => $text,
		font => $self->skin->font,
		size => 10,
		aa => 1,
		color => $self->skin->primaryText,
	) or die "ERROR: " . $self->canvas->errstr;
}

sub _writeTitle($self) {
	my $xval = 1;
	my $yval =  12;
	my $title = truncate($self->title,TITLE_SIZE);
	$self->_writeText($title, $xval, $yval);
}

sub _writeSwimLane($self, $xval, $yval) {
	my $canvas	= $self->canvas;
	my $endY	= $canvas->getheight - 3;
	# $canvas->Draw(
	# 	primitive	=>	'line',
	# 	stroke		=>	$self->{skin}->secondaryFill(),
	# 	points		=>	"${xval}, ".($yval+1)." ${xval}, $endY");
	$canvas->line(
		color => $self->skin->secondaryFill,
		x1    => $xval,
		x2    => $xval,
		y1    => $yval+1,
		y2    => $endY,
		aa    => 1,
		endp  => 1
	);
}

1;
