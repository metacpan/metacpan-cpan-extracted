package LCDRange;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setValue => ['int'];
use QtCore4::signals valueChanged => ['int'];

sub NEW {
    shift->SUPER::NEW(@_);

    my $lcd = Qt::LCDNumber(2);

    my $slider = Qt::Slider(Qt::Horizontal());
    $slider->setRange(0, 99);
    $slider->setValue(0);

    this->connect($slider, SIGNAL "valueChanged(int)",
                  $lcd, SLOT "display(int)");
    this->connect($slider, SIGNAL "valueChanged(int)",
                  this, SIGNAL "valueChanged(int)");

    my $layout = Qt::VBoxLayout;
    $layout->addWidget($lcd);
    $layout->addWidget($slider);
    this->setLayout($layout);
    this->{slider} = $slider;
}

sub value {
    return this->{slider}->value();
}

sub setValue {
    my ( $value ) = @_;
    this->{slider}->setValue($value);
}

1;
