package CannonField;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::signals
	angleChanged => ['int'],
	forceChanged => ['int'];
use Qt::slots
	setAngle => ['int'],
	setForce => ['int'],
	shoot => [],
	moveShot => [];
use Qt::attributes qw(
	ang
	f

	timerCount
	autoShootTimer
	shoot_ang
	shoot_f
);
use POSIX qw(atan);

sub angle () { ang }
sub force () { f }

sub NEW {
    shift->SUPER::NEW(@_);

    ang = 45;
    f = 0;
    timerCount = 0;
    autoShootTimer = Qt::Timer(this, "movement handler");
    this->connect(autoShootTimer, SIGNAL('timeout()'), SLOT('moveShot()'));
    shoot_ang = 0;
    shoot_f = 0;
    setPalette(Qt::Palette(Qt::Color(250, 250, 200)));
}

sub setAngle {
    my $degrees = shift;
    $degrees = 5 if $degrees < 5;
    $degrees = 70 if $degrees > 70;
    return if ang == $degrees;
    ang = $degrees;
    repaint(cannonRect(), 0);
    emit angleChanged(ang);
}

sub setForce {
    my $newton = shift;
    $newton = 0 if $newton < 0;
    return if f == $newton;
    f = $newton;
    emit forceChanged(f);
}

sub shoot {
    return if autoShootTimer->isActive;
    timerCount = 0;
    shoot_ang = ang;
    shoot_f = f;
    autoShootTimer->start(50);
}

sub moveShot {
    my $r = Qt::Region(shotRect());
    timerCount++;

    my $shotR = shotRect();

    if($shotR->x > width() || $shotR->y > height()) {
	autoShootTimer->stop;
    } else {
	$r = $r->unite(Qt::Region($shotR));
    }
    repaint($r);
}

sub paintEvent {
    my $e = shift;
    my $updateR = $e->rect;
    my $p = Qt::Painter(this);

    paintCannon($p)  if $updateR->intersects(cannonRect());
    paintShot($p)    if autoShootTimer->isActive and $updateR->intersects(shotRect());
}

sub paintShot {
    my $p = shift;
    $p->setBrush(&black);
    $p->setPen(&NoPen);
    $p->drawRect(shotRect());
}

my $barrelRect = Qt::Rect(33, -4, 15, 8);

sub paintCannon {
    my $p = shift;
    my $cr = cannonRect();
    my $pix = Qt::Pixmap($cr->size);
    $pix->fill(this, $cr->topLeft);

    my $tmp = Qt::Painter($pix);
    $tmp->setBrush(&blue);
    $tmp->setPen(&NoPen);

    $tmp->translate(0, $pix->height - 1);
    $tmp->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90*16);
    $tmp->rotate(- ang);
    $tmp->drawRect($barrelRect);
    $tmp->end;

    $p->drawPixmap($cr->topLeft, $pix);
}

sub cannonRect {
    my $r = Qt::Rect(0, 0, 50, 50);
    $r->moveBottomLeft(rect()->bottomLeft);
    return $r;
}

sub shotRect {
    my $gravity = 4;

    my $time     = timerCount / 4.0;
    my $velocity = shoot_f;
    my $radians  = shoot_ang*3.14159265/180;

    my $velx     = $velocity*cos($radians);
    my $vely     = $velocity*sin($radians);
    my $x0       = ($barrelRect->right + 5)*cos($radians);
    my $y0       = ($barrelRect->right + 5)*sin($radians);
    my $x        = $x0 + $velx*$time;
    my $y        = $y0 + $vely*$time - 0.5*$gravity*$time**2;

    my $r = Qt::Rect(0, 0, 6, 6);
    $r->moveCenter(Qt::Point(int($x), height() - 1 - int($y)));
    return $r;
}

sub sizePolicy {
    Qt::SizePolicy(&Qt::SizePolicy::Expanding, &Qt::SizePolicy::Expanding);
}

1;
