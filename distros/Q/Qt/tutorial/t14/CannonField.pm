package CannonField;

use Qt;
use QColor;
use QEvent;
use QFont;
use QPainter;
use QPen;
use QPixmap;
use QWidget;
use QWMatrix;

use POSIX 'math_h';  # No atan() in Perl.

use signals 'hit()', 'missed()', 'angleChanged(int)', 'forceChanged(int)';
use slots 'setAngle(int)', 'setForce(int)', 'shoot()', 'newTarget()';
use slots 'setGameOver()', 'restartGame()';

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(@_);

    @$self{'ang', 'f', 'shooting', 'timerCount', 'shoot_ang', 'shoot_f',
	   'gameEnded', 'barrelPressed', 'target'} =
	       (45, 0, 0, 0, 0, 0, 0, 0, new QPoint);
    $self->newTarget();

    return $self;
}

sub angle { return shift->{'ang'} }
sub force { return shift->{'f'} }
sub gameOver { return shift->{'gameEnded'} }
sub isShooting { return shift->{'shooting'} }

sub setAngle {
    my $self = shift;
    my $degrees = shift;

    $degrees = 5 if $degrees < 5;
    $degrees = 70 if $degrees > 70;
    return if $$self{'ang'} == $degrees;
    $$self{'ang'} = $degrees;
    $self->repaint($self->cannonRect(), 0);
    emit $self->angleChanged($$self{'ang'});
}

sub setForce {
    my $self = shift;
    my $newton = shift;

    $newton = 0 if $newton < 0;
    return if $$self{'f'} == $newton;
    $$self{'f'} = $newton;
    emit $self->forceChanged($$self{'f'});
}

sub shoot {
    my $self = shift;

    return if $$self{'shooting'};
    @$self{'timerCount', 'shoot_ang', 'shoot_f', 'shooting'} =
	(0, $$self{'ang'}, $$self{'f'}, 1);
    $self->startTimer(50);
}

# You *ARE* using perl5.004 (or a beta-release), right?
# srand(time ^ $$);

sub newTarget {
    my $self = shift;

    $self->erase($self->targetRect());
    $$self{'target'} = new QPoint(200 + rand(65536) % 190,
				  10  + rand(65536) % 255);
    $self->repaint($self->targetRect());
}

sub setGameOver {
    my $self = shift;

    return if $$self{'gameEnded'};
    $self->stopShooting() if $$self{'shooting'};
    $$self{'gameEnded'} = 1;
    $self->repaint();
}

sub restartGame {
    my $self = shift;

    $self->stopShooting() if $$self{'shooting'};
    $$self{'gameEnded'} = 0;
    $self->repaint();
}

sub timerEvent {
    my $self = shift;

    $self->erase($self->shotRect());
    $$self{'timerCount'}++;

    my $shotR = $self->shotRect();

    if($shotR->intersects($self->targetRect())) {
	$self->stopShooting();
	emit $self->hit();
	return;
    }
    if(($shotR->x() > $self->width() || $shotR->y() > $self->height()) ||
       $shotR->intersects($self->barrierRect())) {
	$self->stopShooting();
	emit $self->missed();
	return;
    }
    $self->repaint($shotR, 0);
}

sub paintEvent {
    my $self = shift;
    my $updateR = shift->rect();
    my $p = new QPainter;
    $p->begin($self);

    $self->paintCannon($p) if $updateR->intersects($self->cannonRect());
    $self->paintBarrier($p) if $updateR->intersects($self->barrierRect());
    if($$self{'gameEnded'}) {
	$p->setPen($black);
	$p->setFont(new QFont('Courier', 48, $Weight{Bold}));
	$p->drawText($self->rect(), $Align{Center}, 'Game Over');
    } else {
	$self->paintShot($p) if $self->isShooting() &&
	    $updateR->intersects($self->shotRect());
	$self->paintTarget($p) if $updateR->intersects($self->targetRect());
    }
    $p->end();
}

sub mousePressEvent {
    my $self = shift;
    my $e = shift;

    return if $e->button() != $LeftButton;
    $$self{'barrelPressed'} = 1 if $self->barrelHit($e->pos());
}

sub mouseMoveEvent {
    my $self = shift;
    my $e = shift;

    return unless $$self{'barrelPressed'};
    my $pnt = $e->pos();
    $pnt->setX(1) if $pnt->x() <= 0;
    $pnt->setY($self->height() - 1) if $pnt->y() >= $self->height();
    my $rad = atan(($self->rect()->bottom() - $pnt->y()) / $pnt->x());
    $self->setAngle(qRound($rad*180/3.14159265));
}

sub mouseReleaseEvent {
    my $self = shift;
    my $e = shift;

    $$self{'barrelPressed'} = 0 if $e->button() == $LeftButton;
}

sub stopShooting {
    my $self = shift;

    $$self{'shooting'} = 0;
    $self->killTimers();
}

sub paintShot {
    my $self = shift;
    my $p = shift;

    $p->setBrush($black);
    $p->setPen($PenStyle{NoPen});
    $p->drawRect($self->shotRect());
}

sub paintTarget {
    my $self = shift;
    my $p = shift;

    $p->setBrush($red);
    $p->setPen($black);
    $p->drawRect($self->targetRect());
}

sub paintBarrier {
    my $self = shift;
    my $p = shift;

    $p->setBrush($yellow);
    $p->setPen($black);
    $p->drawRect($self->barrierRect());
}

$barrel_rect = new QRect(33, -4, 15, 8);

sub paintCannon {
    my $self = shift;
    my $p = shift;
    my $cr = $self->cannonRect();
    my $pix = new QPixmap($cr->size());
    my $tmp = new QPainter;

    $pix->fill($self, $cr->topLeft());

    $tmp->begin($pix);
    $tmp->setBrush($blue);
    $tmp->setPen($PenStyle{NoPen});

    $tmp->translate(0, $pix->height() - 1);
    $tmp->drawPie(new QRect(-35, -35, 70, 70), 0, 90*16);
    $tmp->rotate(-$$self{'ang'});
    $tmp->drawRect($barrel_rect);
    $tmp->end();

    $p->drawPixmap($cr->topLeft(), $pix);
}

sub cannonRect {
    my $self = shift;
    my $r = new QRect(0, 0, 50, 50);

    $r->moveBottomLeft($self->rect()->bottomLeft());
    return $r;
}

sub shotRect {
    my $self = shift;

    my $gravity  = 4;

    my $time     = $$self{'timerCount'}/4.0;
    my $velocity = $$self{'shoot_f'}/0.7;
    my $radians  = $$self{'shoot_ang'}*3.14159265/180;

    my $velx = $velocity*cos($radians);
    my $vely = $velocity*sin($radians);
    my $x0   = ($barrel_rect->right() + 5)*cos($radians);
    my $y0   = ($barrel_rect->right() + 5)*sin($radians);
    my $x    = $x0 + $velx*$time;
    my $y    = $y0 + $vely*$time - $gravity*$time*$time;

    my $r = new QRect(0, 0, 6, 6);
    $r->moveCenter(new QPoint(qRound($x), $self->height() - 1 - qRound($y)));
    return $r;
}

sub targetRect {
    my $self = shift;
    my $target = $$self{'target'};
    my $r = new QRect(0, 0, 20, 10);

    $r->moveCenter(new QPoint($target->x(), $self->height() - 1 -
			      $target->y()));
    return $r;
}

sub barrierRect {
    my $self = shift;

    return new QRect(145, $self->height() - 100, 15, 100);
}

sub barrelHit {
    my $self = shift;
    my $p = shift;
    my $mtx = new QWMatrix;

    $mtx->translate(0, $self->height() - 1);
    $mtx->rotate(-$$self{'ang'});
    $mtx = $mtx->invert();
    return $barrel_rect->contains($mtx->map($p));
}
