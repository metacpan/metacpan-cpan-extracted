package CanonField;

#use blib;
use Qt;
use Qt::QString;
use Qt::QPainter;
use Qt::QPalette;
use Qt::QColor;
use Qt::QWidget;

our @ISA = qw(Qt::QWidget);
our @EXPORT = qw(CanonField);


sub CanonField {
    my $class = 'CanonField';
    my @signals = ('angleChanged(int)');
    my @slots = ('setAngle(int)');
    my $this = QWidget(\@signals, \@slots);
    bless $this, $class;
    
    $this->{currentAngle} = 45;
    $this->setPalette(QPalette(QColor(250, 250, 200)));
    $this->setAutoFillBackground(1); # 1 == true

    return $this;
}

sub angle {
    $this = shift;
    return $this->{currentAngle};
}

sub setAngle {
    my $this = shift;
    my $angle = shift;
    if ( $angle < 5 ) {
	$angle = 5;
    }
    elsif ( $angle > 70 ) {
	$angle = 70;
    }
    return if $this->{currentAngle} == $angle;
    
    $this->{currentAngle} = $angle;
    $this->update();
    $this->emit('angleChanged(int)', $this->{currentAngle});
}

sub paintEvent { # yet not support virtual function from base classes
    my $this = shift;
    my $painter = QPainter($this);
    $painter->drawText(200, 200, QString("Angle = $$this{currentAngle}"));
}

1;
