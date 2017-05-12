package LCDRange;

use Qt;
use QLCDNumber;
use QScrollBar;

use signals 'valueChanged(int)';
use slots 'setValue(int)';

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(@_);

    my $lcd = new QLCDNumber(2, $self, 'lcd');
    $lcd->move(0, 0);
    my $sBar =
	new QScrollBar(0, 99,				# range
		       1, 10,				# line/page steps
		       0,				# initial value
		       $Orientation{Horizontal},	# orientation
		       $self, 'scrollbar');
    $lcd->connect($sBar, 'valueChanged(int)', 'display(int)');
    $self->connect($sBar, 'valueChanged(int)', 'valueChanged(int)');

    @$self{'sBar', 'lcd'} = ($sBar, $lcd);
    return $self;
}

sub value { return shift->{'sBar'}->value() }

sub setValue {
    my $self = shift;
    my $value = shift;

    $$self{'sBar'}->setValue($value);
}

sub resizeEvent {
    my $self = shift;
    my($sBar, $lcd) = @$self{'sBar', 'lcd'};

    $sBar->setGeometry(0, $self->height() - 16, $self->width(), 16);
    $lcd->resize($self->width(), $sBar->y() - 5);
}
