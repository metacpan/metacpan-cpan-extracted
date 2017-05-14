package SlidersGroup;

#use blib;
use Qt;
use Qt::QDial;
use Qt::QScrollBar;
use Qt::QSlider;
use Qt::QGroupBox;
use Qt::QBoxLayout;

our @ISA = qw(Qt::QGroupBox);
our @EXPORT = qw(SlidersGroup);


sub SlidersGroup {
    my $class = 'SlidersGroup';
    my $orientation = shift;
    my $title = shift;
    my @signals = ('valueChanged(int)');
    my @slots = ('setValue(int)', 'setMinimum(int)', 'setMaximum(int)', 'invertAppearance(bool)', 'invertKeyBindings(bool)');
    my $this = QGroupBox(\@signals, \@slots, $title);
    bless $this, $class;

    $this->{slider} = QSlider($orientation);
    $this->{slider}->setFocusPolicy(Qt::StrongFocus);
    $this->{slider}->setTickPosition(Qt::QSlider::TicksBothSides);
    $this->{slider}->setTickInterval(10);
    $this->{slider}->setSingleStep(1);

    $this->{scrollBar} = QScrollBar($orientation);
    $this->{scrollBar}->setFocusPolicy(Qt::StrongFocus);

    $this->{'dial'} = QDial();
    $this->{'dial'}->setFocusPolicy(Qt::StrongFocus);

    $this->connect($this->{slider}, SIGNAL('valueChanged(int)'), $this->{scrollBar}, SLOT('setValue(int)'));
    $this->connect($this->{scrollBar}, SIGNAL('valueChanged(int)'), $this->{'dial'}, SLOT('setValue(int)'));
    $this->connect($this->{'dial'}, SIGNAL('valueChanged(int)'), $this->{slider}, SLOT('setValue(int)'));
    $this->connect($this->{'dial'}, SIGNAL('valueChanged(int)'), $this, SIGNAL('valueChanged(int)'));

    if ( $orientation == Qt::Horizontal ) {
        $this->{slidersLayout} = QBoxLayout(Qt::QBoxLayout::TopToBottom); }
    else {
        $this->{slidersLayout} = QBoxLayout(Qt::QBoxLayout::LeftToRight); }
    $this->{slidersLayout}->addWidget($this->{slider});
    $this->{slidersLayout}->addWidget($this->{scrollBar});
    $this->{slidersLayout}->addWidget($this->{'dial'});
    $this->setLayout($this->{slidersLayout});

    return $this;
}


sub setValue {
    my $this = shift;
    my $value = shift;
    $this->{slider}->setValue($value);
}


sub setMinimum {
    my $this = shift;
    my $value = shift;
    $this->{slider}->setMinimum($value);
    $this->{scrollBar}->setMinimum($value);
    $this->{'dial'}->setMinimum($value);
}


sub setMaximum {
    my $this = shift;
    my $value = shift;
    $this->{slider}->setMaximum($value);
    $this->{scrollBar}->setMaximum($value);
    $this->{'dial'}->setMaximum($value);
}


sub invertAppearance {
    my $this = shift;
    my $invert = shift;
    $this->{slider}->setInvertedAppearance($invert);
    $this->{scrollBar}->setInvertedAppearance($invert);
    $this->{'dial'}->setInvertedAppearance($invert);
}


sub invertKeyBindings {
    my $this = shift;
    my $invert = shift;
    $this->{slider}->setInvertedControls($invert);
    $this->{scrollBar}->setInvertedControls($invert);
    $this->{'dial'}->setInvertedControls($invert);
}

1;

