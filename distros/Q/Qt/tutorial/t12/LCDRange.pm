package LCDRange;

use Qt;
use QLabel;
use QLCDNumber;
use QScrollBar;

use signals 'valueChanged(int)';
use slots 'setValue(int)', 'setRange(int,int)', 'setText(string)';

@ISA = qw(QWidget);

sub new {
    my $text = (ref $_[1]) ? undef : splice(@_, 1, 1);
    my $self = shift->SUPER::new(@_);

    $self->init();
    $self->setText($text) if $text;

    return $self;
}

sub init {
    my $self = shift;

    my $lcd = new QLCDNumber(2, $self, 'lcd');
    $lcd->move(0, 0);
    my $sBar =
	new QScrollBar(0, 99,				# range
		       1, 10,				# line/page steps
		       0,				# initial value
		       $Orientation{Horizontal},	# orientation
		       $self, 'scrollbar');
    my $label = new QLabel($self, 'label');
    $label->setAlignment($Align{Center});
    $lcd->connect($sBar, 'valueChanged(int)', 'display(int)');
    $self->connect($sBar, 'valueChanged(int)', 'valueChanged(int)');

    @$self{'sBar', 'lcd', 'label'} = ($sBar, $lcd, $label);
}

sub value { return shift->{'sBar'}->value() }
sub text { return shift->{'label'}->text() }

sub setValue {
    my $self = shift;
    my $value = shift;

    $$self{'sBar'}->setValue($value);
}

sub setRange {
    my $self = shift;
    my $minVal = shift;
    my $maxVal = shift;

    if($minVal < 0 || $maxVal > 99 || $minVal > $maxVal) {
	warn "LCDRange::setRange($minVal, $maxVal)
	Range must be 0..99
	and minVal must not be greater than maxVal";
	return;
    }
    $$self{'sBar'}->setRange($minVal, $maxVal);
}

sub setText {
    my $self = shift;
    my $text = shift;

    $$self{'label'}->setText($text);
}

sub resizeEvent {
    my $self = shift;
    my($sBar, $lcd, $label) = @$self{'sBar', 'lcd', 'label'};

    $lcd->resize($self->width(), $self->height() - 41 - 5);
    $sBar->setGeometry(0, $lcd->height() + 5, $self->width(), 16);
    $label->setGeometry(0, $lcd->height() + 16 + 5, $self->width(), 20);
}
