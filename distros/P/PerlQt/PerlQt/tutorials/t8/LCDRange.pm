package LCDRange;
use strict;
use Qt;
use Qt::isa qw(Qt::VBox);
use Qt::slots 
	setValue => ['int'],
	setRange => ['int', 'int'];
use Qt::signals
	valueChanged => ['int'];
use Qt::attributes qw(
	slider
);

sub NEW {
    shift->SUPER::NEW(@_);

    my $lcd = Qt::LCDNumber(2, this, "lcd");

    slider = Qt::Slider(&Horizontal, this, "slider");
    slider->setRange(0, 99);
    slider->setValue(0);
    $lcd->connect(slider, SIGNAL('valueChanged(int)'), SLOT('display(int)'));
    this->connect(slider, SIGNAL('valueChanged(int)'), SIGNAL('valueChanged(int)'));

    setFocusProxy(slider);
}

sub value { slider->value }

sub setValue { slider->setValue(shift) }

sub setRange {
    my($minVal, $maxVal) = @_;
    if($minVal < 0 || $maxVal > 99 || $minVal > $maxVal) {
	warn "LCDRange::setRange($minVal,$maxVal)\n" .
	     "\tRange must be 0..99\n" .
	     "\tand minVal must not be greater than maxVal\n";
	return;
    }
    slider->setRange($minVal, $maxVal);
}

1;
