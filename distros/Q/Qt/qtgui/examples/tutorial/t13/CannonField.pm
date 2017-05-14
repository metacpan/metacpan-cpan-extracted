package CannonField;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setAngle    => ['int'],
              setForce    => ['int'],
              shoot       => [],
              newTarget   => [],
              setGameOver => [],
              restartGame => [],
              moveShot    => [];
use QtCore4::signals hit          => [],
                missed       => [],
                angleChanged => ['int'],
                forceChanged => ['int'],
                canShoot     => ['bool'];

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
    this->{target} = Qt::Point(0, 0);
    this->{gameEnded} = 0;
    this->setPalette(Qt::Palette(Qt::Color(250,250,200)));
    this->setAutoFillBackground(1);
    this->{firstTime} = 1;
    newTarget();
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
    if (isShooting()) {
        return;
    }
    this->{timerCount} = 0;
    this->{shootAngle} = this->{currentAngle};
    this->{shootForce} = this->{currentForce};
    this->{autoShootTimer}->start(5);
    emit canShoot( 0 );
}

sub newTarget {
    if (this->{firstTime}) {
        this->{firstTime} = 0;
        srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`);
    }

    # 2147483647 is the value of RAND_MAX, defined in stdlib.h, at least on my machine.
    # See the Qt4 4.2 documentation on qrand() for more details.
    this->{target} = Qt::Point( 150 + rand(2147483647) % 190, 10 + rand(2147483647) % 255);
    this->update();
}

sub setGameOver {
    return if (this->{gameEnded});
    if (this->isShooting()) {
        this->{autoShootTimer}->stop();
    }
    this->{gameEnded} = 1;
    emit canShoot(0);
    this->update();
}

sub restartGame {
    if (isShooting()) {
        this->{autoShootTimer}->stop();
    }
    this->{gameEnded} = 0;
    this->update();
    emit canShoot( 1 );
}

sub moveShot {
    my $region = shotRect();
    this->{timerCount}++;

    my $shotR = shotRect();

    if ($shotR->intersects(targetRect())) {
        this->{autoShootTimer}->stop();
        emit canShoot( 1 );
        emit hit();
    }
    elsif ($shotR->x() > this->width() || $shotR->y() > this->height()) {
        this->{autoShootTimer}->stop();
        emit canShoot( 1 );
        emit missed();
    }
    else {
        $region = $region->unite($shotR);
    }
    this->update($region);
}

my $barrelRect = Qt::Rect(30, -5, 20, 10);

sub paintEvent {
    my $painter = Qt::Painter(this);

    if (this->{gameEnded}) {
        $painter->setPen(Qt::Color(0, 0, 0));
        $painter->setFont(Qt::Font("Courier", 48, Qt::Font::Bold()));
        $painter->drawText(this->rect(), Qt::AlignCenter(), "Game Over");
    }
    if (isShooting()){
        paintShot($painter);
    }
    if (!this->{gameEnded}) {
        paintTarget($painter);
    }
    paintCannon($painter);

    $painter->end();
}

sub paintShot {
    my( $painter ) = @_;
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::black()));
    $painter->drawRect(shotRect());
}

sub paintTarget {
    my( $painter ) = @_;
    $painter->setPen(Qt::Color(0, 0, 0));
    $painter->setBrush(Qt::Brush(Qt::red()));
    $painter->drawRect(targetRect());
}

sub paintCannon {
    my( $painter ) = @_;
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::blue()));

    $painter->translate(0, this->rect()->height());
    $painter->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90 * 16);
    $painter->rotate(-(this->{currentAngle}));
    $painter->drawRect($barrelRect);
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

sub targetRect {
    my $result = Qt::Rect(0, 0, 20, 10);
    my $target = this->{target};
    $result->moveCenter(Qt::Point($target->x(), this->height() - 1 - $target->y()));
    return $result;
}

sub isShooting {
    return this->{autoShootTimer}->isActive();
}
1;
