package AnalogClock;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::slots
	setTime => ['const QTime&'],
	drawClock => ['QPainter*'],
	timeout => [];
use Qt::attributes qw(
	clickPos
	_time
);

#
# Constructs an analog clock widget that uses an internal QTimer
#

sub NEW {
    shift->SUPER::NEW(@_);
    _time = Qt::Time::currentTime();	  # get current time
    my $internalTimer = Qt::Timer(this);  # create internal timer
    this->connect($internalTimer, SIGNAL('timeout()'), SLOT('timeout()'));
    $internalTimer->start(5000);	  # emit signal every 5 seconds
}

sub mousePressEvent {
    my $e = shift;
    if(isTopLevel()) {
	# Lack of operators is really noticable here
	my $topLeft = Qt::Point(
	    geometry()->topLeft->x - frameGeometry()->topLeft->x,
	    geometry()->topLeft->y - frameGeometry()->topLeft->y
	);
	clickPos = Qt::Point($e->pos->x + $topLeft->x,
			     $e->pos->y + $topLeft->y);
    }
}

sub mouseMoveEvent {
    my $e = shift;
    if(isTopLevel()) {
	move(Qt::Point($e->globalPos->x - clickPos->x,
		       $e->globalPos->y - clickPos->y));
    }
}

sub setTime {
    my $t = shift;
    timeout();
}

#
# The QTimer::timeout() signal is received by this slot.
#

sub timeout {
    my $new_time = Qt::Time::currentTime();	# get the current time
    _time = _time->addSecs(5);
    if($new_time->minute != _time->minute) {	# minute has changed
	if(autoMask()) {
	    updateMask();
	} else {
	    update();
	}
    }
}

sub paintEvent {
    return if autoMask();
    my $paint = Qt::Painter(this);
    $paint->setBrush(colorGroup()->foreground);
    drawClock($paint);
}

# If clock is transparent, we use updateMask()
# instead of paintEvent()

sub updateMask {			# paint clock mask
    my $bm = Qt::Bitmap(size());
    $bm->fill(&color0);			# transparent

    my $paint = Qt::Painter;
    $paint->begin($bm, this);
    $paint->setBrush(&color1);		# use non-transparent color
    $paint->setPen(&color1);

    drawClock($paint);

    $paint->end;
    setMask($bm);
}

#
# The clock is painted using a 1000x1000 square coordinate system, in
# the centered square, as big as possible.  The painter's pen and
# brush colors are used.
#
sub drawClock {
    my $paint = shift;
    $paint->save;

    $paint->setWindow(-500,-500, 1000,1000);

    my $v = $paint->viewport;
    my $d = min($v->width, $v->height);
    $paint->setViewport($v->left + ($v->width-$d)/2,
			$v->top - ($v->height-$d)/2, $d, $d);

    # _time = Qt::Time::currentTime();
    my $pts = Qt::PointArray();

    $paint->save;
    $paint->rotate(30*(_time->hour%12-3) + _time->minute/2);
    $pts->setPoints([-20,0, 0,-20, 300,0, 0,20]);
    $paint->drawConvexPolygon($pts);
    $paint->restore;

    $paint->save;
    $paint->rotate((_time->minute-15)*6);
    $pts->setPoints([-10,0, 0,-10, 400,0, 0,10]);
    $paint->drawConvexPolygon($pts);
    $paint->restore;

    for(1 .. 12) {
	$paint->drawLine(440,0, 460,0);
	$paint->rotate(30);
    }

    $paint->restore;
}

sub setAutoMask {
    my $b = shift;
    setBackgroundMode($b ? &PaletteForeground : &PaletteBackground);
    Qt::Widget::setAutoMask($b);
}

1;
