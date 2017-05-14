package CannonField;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setAngle => ['int'],
              setForce => ['int'],
              shoot    => [],
              moveShot => [];
use QtCore4::signals angleChanged => ['int'],
                forceChanged => ['int'];

sub NEW {
    shift->SUPER::NEW(@_);

    this->{currentAngle} = 45;
    this->{currentForce} = 0;
    this->{timerCount} = 0;
    my $autoShootTimer = Qt::Timer(this);
    this->{autoShootTimer} = $autoShootTimer;
    this->connect( $autoShootTimer, SIGNAL 'timeout()', this, SLOT 'moveShot()' );
    this->{shootAngle} = 0;
    this->{shootForce} = 0;
    this->setPalette(Qt::Palette(Qt::Color(250,250,200)));
    this->setAutoFillBackground(1);
}

sub setAngle {
    my ( $angle ) = @_;
    if ($angle < 5) {
        $angle = 5;
    }
    if ($angle > 70) {
        $angle = 70;
    }
    if (this->{currentAngle} == $angle) {
        return;
    }
    this->{currentAngle} = $angle;
    this->update(this->cannonRect());
    emit angleChanged( this->{currentAngle} );
}

sub setForce {
    my ( $force ) = @_;
    if ($force < 0) {
        $force = 0;
    }
    if (this->{currentForce} == $force) {
        return;
    }
    this->{currentForce} = $force;
    emit forceChanged( this->{currentForce} );
}

sub shoot {
    my $autoShootTimer = this->{autoShootTimer};
    if ($autoShootTimer->isActive()) {
        return;
    }
    this->{timerCount} = 0;
    this->{shootAngle} = this->{currentAngle};
    this->{shootForce} = this->{currentForce};
    $autoShootTimer->start(5);
}

sub moveShot {
    my $region = shotRect();
    this->{timerCount}++;

    my $shotR = shotRect();

    if ($shotR->x() > this->width() || $shotR->y() > this->height()) {
        this->{autoShootTimer}->stop();
    }
    else {
        $region = $region->unite($shotR);
    }
    this->update($region);
}

my $barrelRect = Qt::Rect(30, -5, 20, 10);

sub paintEvent {
    my $painter = Qt::Painter(this);

    if (this->{autoShootTimer}->isActive()){
        #paintShot($painter);
        $painter->setPen(Qt::NoPen());
        $painter->setBrush(Qt::Brush(Qt::black()));
        $painter->drawRect(shotRect());
    }
    #paintCannon($painter);
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::blue()));

    $painter->translate(0, this->rect()->height());
    $painter->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90 * 16);
    $painter->rotate(-(this->{currentAngle}));
    $painter->drawRect($barrelRect);

    $painter->end();
}

sub cannonRect {
    my $result = Qt::Rect(0, 0, 50, 50);
    $result->moveBottomLeft(this->rect()->bottomLeft());
    return $result;
}

sub shotRect {
    my $gravity = 4;
    my $time = this->{timerCount} / 20.0;
    my $velocity = this->{shootForce};
    my $radians = this->{shootAngle} * 3.14159265 / 180;

    my $velx = $velocity * cos($radians);
    my $vely = $velocity * sin($radians);
    my $x0 = ($barrelRect->right() + 5) * cos($radians);
    my $y0 = ($barrelRect->right() + 5) * sin($radians);
    my $x = $x0 + $velx * $time;
    my $y = $y0 + $vely * $time - 0.5 * $gravity * $time * $time;

    $x = int($x + .5);
    $y = int($y + .5);

    my $result = Qt::Rect(0, 0, 6, 6);
    $result->moveCenter(Qt::Point( $x, this->height() - 1 - $y ));
    return $result;
}

1;
