package LCDRange;
use strict;
use Qt;
use Qt::isa qw(Qt::VBox);
use Qt::slots setValue => ['int'];
use Qt::signals valueChanged => ['int'];
use Qt::attributes qw(slider);

sub NEW {
    shift->SUPER::NEW(@_);

    my $lcd = Qt::LCDNumber(2, this, "lcd");

    my $slider = Qt::Slider(&Horizontal, this, "slider");
    slider = $slider;
    slider->setRange(0, 99);
    slider->setValue(0);
    $lcd->connect(slider, SIGNAL('valueChanged(int)'), SLOT('display(int)'));
    this->connect(slider, SIGNAL('valueChanged(int)'), SIGNAL('valueChanged(int)'));
}

sub value { slider->value }

sub setValue {
    my $value = shift;
    slider->setValue($value);
}

1;
