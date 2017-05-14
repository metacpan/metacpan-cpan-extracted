package LCDRange;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use QtCore4::slots setValue => ['int'],
              setRange => ['int', 'int'];
use QtCore4::signals valueChanged => ['int'];

sub NEW {
    my( $class, $parent, $text ) = @_;
    $class->SUPER::NEW($parent);

    init();

    if( $text ) {
        setText($text);
    }
}

sub init {
    my $lcd = Qt::LCDNumber(2);
    $lcd->setSegmentStyle(Qt::LCDNumber::Filled());

    my $slider = Qt::Slider(Qt::Horizontal());
    $slider->setRange(0, 99);
    $slider->setValue(0);
    my $label = Qt::Label();
    $label->setAlignment(Qt::AlignHCenter() | Qt::AlignTop());

    this->connect($slider, SIGNAL "valueChanged(int)",
                  $lcd, SLOT "display(int)");
    this->connect($slider, SIGNAL "valueChanged(int)",
                  this, SIGNAL "valueChanged(int)");

    my $layout = Qt::VBoxLayout;
    $layout->addWidget($lcd);
    $layout->addWidget($slider);
    $layout->addWidget($label);
    this->setLayout($layout);

    this->setFocusProxy($slider);

    this->{slider} = $slider;
    this->{label} = $label;
}

sub value {
    return this->{slider}->value();
}

sub setValue {
    my ( $value ) = @_;
    this->{slider}->setValue($value);
}

sub setRange {
    my ( $minValue, $maxValue ) = @_;
    if (($minValue < 0) || ($maxValue > 99) || ($minValue > $maxValue)) {
        Qt::qWarning("LCDRange::setRange(%d, %d)\n" .
                     "\tRange must be 0..99\n" .
                     "\tand minValue must not be greater than maxValue",
                     $minValue, $maxValue);
        return;
    }
    this->{slider}->setRange($minValue, $maxValue);
}

sub setText {
    my ( $text ) = @_;
    this->{label}->setText($text);
}

1;
