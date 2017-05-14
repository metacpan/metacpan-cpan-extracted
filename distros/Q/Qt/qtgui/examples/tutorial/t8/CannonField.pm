package CannonField;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setAngle => ['int'];
use QtCore4::signals angleChanged => ['int'];

sub NEW {
    shift->SUPER::NEW(@_);

    this->{currentAngle} = 45;
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
    this->update();
    this->emit( 'angleChanged', this->{currentAngle} );
}

sub paintEvent {
    my $painter = Qt::Painter( this );
    $painter->drawText(200, 200, "Angle = " . this->{currentAngle} );
    $painter->end();
}

1;
