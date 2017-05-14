package LEDWidget;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Label );
use QtCore4::slots
    flash => [],
    extinguish => [];

sub onPixmap() {
    return this->{onPixmap};
}

sub offPixmap() {
    return this->{offPixmap};
}

sub flashTimer() {
    return this->{flashTimer};
}

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->{onPixmap} = Qt::Pixmap(':/ledon.png');
    this->{offPixmap} = Qt::Pixmap(':/ledoff.png');
    this->setPixmap(this->offPixmap());
    this->{flashTimer} = Qt::Timer();
    this->flashTimer->setInterval(200);
    this->flashTimer->setSingleShot(1);
    this->connect(this->flashTimer, SIGNAL 'timeout()', this, SLOT 'extinguish()');
}

sub extinguish {
    this->setPixmap(this->offPixmap());
}

sub flash {
    this->setPixmap(this->onPixmap());
    this->flashTimer->start();
}

1;
