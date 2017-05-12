package CannonField;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::signals
	hit => [],
	missed => [],
	angleChanged => ['int'],
	forceChanged => ['int'],
	canShoot => ['bool'];
use Qt::slots
	setAngle => ['int'],
	setForce => ['int'],
	shoot => [],
	moveShot => [],
	newTarget => [],
	setGameOver => [],
	restartGame => [];
use Qt::attributes qw(
	ang
	f

	timerCount
	autoShootTimer
	shoot_ang
	shoot_f

	target

	gameEnded
	barrelPressed
);
use POSIX qw(atan);

sub angle () { ang }
sub force () { f }
sub gameOver () { gameEnded }

sub NEW {
    shift->SUPER::NEW(@_);

    ang = 45;
    f = 0;
    timerCount = 0;
    autoShootTimer = Qt::Timer(this, "movement handler");
    this->connect(autoShootTimer, SIGNAL('timeout()'), SLOT('moveShot()'));
    shoot_ang = 0;
    shoot_f = 0;
    target = Qt::Point(0, 0);
    gameEnded = 0;
    barrelPressed = 0;
    setPalette(Qt::Palette(Qt::Color(250, 250, 200)));
    newTarget();
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
    return if isShooting();
    timerCount = 0;
    shoot_ang = ang;
    shoot_f = f;
    autoShootTimer->start(50);
    emit canShoot(0);
}

sub newTarget {
    my $r = Qt::Region(targetRect());
    target = Qt::Point(200 + int(rand(190)),
		       10  + int(rand(255)));
    repaint($r->unite(Qt::Region(targetRect())));
}

sub setGameOver {
    return if gameEnded;
    autoShootTimer->stop if isShooting();
    gameEnded = 1;
    repaint();
}

sub restartGame {
    autoShootTimer->stop if isShooting();
    gameEnded = 0;
    repaint();
    emit canShoot(1);
}

sub moveShot {
    my $r = Qt::Region(shotRect());
    timerCount++;

    my $shotR = shotRect();

    if($shotR->intersects(targetRect())) {
	autoShootTimer->stop;
	emit hit();
	emit canShoot(1);
    } elsif($shotR->x > width() || $shotR->y > height() ||
	    $shotR->intersects(barrierRect())) {
	autoShootTimer->stop;
	emit missed();
	emit canShoot(1);
    } else {
	$r = $r->unite(Qt::Region($shotR));
    }
    repaint($r);
}

sub mousePressEvent {
    my $e = shift;
    return if $e->button != &LeftButton;
    barrelPressed = 1 if barrelHit($e->pos);
}

sub mouseMoveEvent {
    my $e = shift;
    return unless barrelPressed;
    my $pnt = $e->pos;
    $pnt->setX(1) if $pnt->x <= 0;
    $pnt->setY(height() - 1) if $pnt->y >= height();
    my $rad = atan((rect()->bottom - $pnt->y) / $pnt->x);
    setAngle(int($rad*180/3.14159265));
}

sub mouseReleaseEvent {
    my $e = shift;
    barrelPressed = 0 if $e->button == &LeftButton;
}

sub paintEvent {
    my $e = shift;
    my $updateR = $e->rect;
    my $p = Qt::Painter(this);

    if(gameEnded) {
	$p->setPen(&black);
	$p->setFont(Qt::Font("Courier", 48, &Qt::Font::Bold));
	$p->drawText(rect(), &AlignCenter, "Game Over");
    }
    paintCannon($p)  if $updateR->intersects(cannonRect());
    paintBarrier($p) if $updateR->intersects(barrierRect());
    paintShot($p)    if isShooting() and $updateR->intersects(shotRect());
    paintTarget($p)  if !gameEnded and $updateR->intersects(targetRect());
}

sub paintShot {
    my $p = shift;
    $p->setBrush(&black);
    $p->setPen(&NoPen);
    $p->drawRect(shotRect());
}

sub paintTarget {
    my $p = shift;
    $p->setBrush(&red);
    $p->setPen(&black);
    $p->drawRect(targetRect());
}

sub paintBarrier {
    my $p = shift;
    $p->setBrush(&yellow);
    $p->setPen(&black);
    $p->drawRect(barrierRect());
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

sub targetRect {
    my $r = Qt::Rect(0, 0, 20, 10);
    $r->moveCenter(Qt::Point(target->x, height() - 1 - target->y));
    return $r;
}

sub barrierRect {
    return Qt::Rect(145, height() - 100, 15, 100);
}

sub barrelHit {
    my $p = shift;
    my $mtx = Qt::WMatrix;
    $mtx->translate(0, height() - 1);
    $mtx->rotate(- ang);
    $mtx = $mtx->invert;
    return $barrelRect->contains($mtx->map($p));
}

sub isShooting { autoShootTimer->isActive }

sub sizeHint { Qt::Size(400, 300) }

sub sizePolicy {
    Qt::SizePolicy(&Qt::SizePolicy::Expanding, &Qt::SizePolicy::Expanding);
}

1;
