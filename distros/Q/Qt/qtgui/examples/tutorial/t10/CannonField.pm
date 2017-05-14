package CannonField;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setAngle => ['int'],
              setForce => ['int'];
use QtCore4::signals angleChanged => ['int'],
                forceChanged => ['int'];

sub NEW {
    shift->SUPER::NEW(@_);

    this->{currentAngle} = 45;
    this->{currentForce} = 0;
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
    this->update();
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
    this->emit( 'forceChanged', this->{currentForce} );
}

sub paintEvent {
    my $painter = Qt::Painter(this);

    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::blue()));

    $painter->translate(0, this->rect()->height());
    $painter->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90 * 16);
    $painter->rotate(-(this->{currentAngle}));
    $painter->drawRect(Qt::Rect(30, -5, 20, 10));
    $painter->end();
}

sub cannonRect {
    my $result = Qt::Rect(0, 0, 50, 50);
    $result->moveBottomLeft(this->rect()->bottomLeft());
    return $result;
}

1;
