package LCDRange;
use strict;
use Qt;
use Qt::isa qw(Qt::VBox);
use Qt::slots 
	setValue => ['int'],
	setRange => ['int', 'int'],
	setText => ['const char*'];
use Qt::signals
	valueChanged => ['int'];
use Qt::attributes qw(
	slider
	label
);

sub NEW {
    my $class = shift;
    my $s;
    $s = shift if $_[0] and not ref $_[0];
    $class->SUPER::NEW(@_);

    init();
    setText($s) if $s;
}


sub init {
    my $lcd = Qt::LCDNumber(2, this, "lcd");

    slider = Qt::Slider(&Horizontal, this, "slider");
    slider->setRange(0, 99);
    slider->setValue(0);

    label = Qt::Label(" ", this, "label");
    label->setAlignment(&AlignCenter);

    $lcd->connect(slider, SIGNAL('valueChanged(int)'), SLOT('display(int)'));
    this->connect(slider, SIGNAL('valueChanged(int)'), SIGNAL('valueChanged(int)'));

    setFocusProxy(slider);
}

sub value { slider->value }

sub text { label->text }

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

sub setText { label->setText(shift) }

1;
