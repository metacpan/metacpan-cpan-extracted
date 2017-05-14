package LCDRange;

# use blib;
use Qt;
use Qt::QWidget;
use Qt::QLCDNumber;
use Qt::QSlider;
use Qt::QBoxLayout;

our @ISA = qw(Qt::QWidget);
our @EXPORT=qw(LCDRange);

sub LCDRange {
    my $class = 'LCDRange';
    my @signals = ('valueChanged(int)');
    my @slots = ('setValue(int)');
    my $this = QWidget(\@signals, \@slots);
    bless $this, $class;

    $this->{lcd} = QLCDNumber(2);
    $this->{lcd}->setSegmentStyle(Qt::QLCDNumber::Filled);
    
    $this->{slider} = QSlider(Qt::Horizontal);
    $this->{slider}->setRange(0, 99);
    $this->{slider}->setValue(0);
    
    $this->connect($this->{slider}, SIGNAL('valueChanged(int)'), $this->{lcd}, SLOT('display(int)'));
    $this->connect($this->{slider}, SIGNAL('valueChanged(int)'), $this, SIGNAL('valueChanged(int)'));
    
    $this->{layout} = QVBoxLayout();
    $this->{layout}->addWidget($this->{lcd});
    $this->{layout}->addWidget($this->{slider});
    $this->setLayout($this->{layout});
    
    return $this;
}


sub value {
    $this = shift;
    return $this->{slider}->value();
}    

sub setValue {
    $this = shift;
    $value = shift;
    $this->{slider}->setValue($value);
}

1;
