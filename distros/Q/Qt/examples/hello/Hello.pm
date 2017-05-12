package Hello;

use QColor;
use QObject;
use QPainter;
use QPixmap;
use QPushButton;
use QTimer;
use QWidget;

use signals 'clicked()';
use slots 'animate()';

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(@_[1..$#_]);
    @$self{'t', 'b'} = (shift, 0);

    $timer = new QTimer($self);
    $self->connect($timer, 'timeout()', 'animate()');
    $timer->start(40);

    $self->resize(200, 100);

    return $self;
}

sub animate {
    my $self = shift;

    $$self{'b'} = ($$self{'b'}+1) & 15;
    $self->repaint(0);
}

sub mouseReleaseEvent {
    my $self = shift;
    my $e = shift;

    emit $self->clicked() if $self->rect()->contains($e->pos());
}

{
    my @sin_tbl = (0, 38, 71, 92, 100, 92, 71, 38, 0, -38, -71, -92,
		   -100, -92, -71, -38);

    sub paintEvent {
	my $self = shift;
	my $t = $$self{'t'};

	return unless $t;

	my $fm = $self->fontMetrics();
	my $w = $fm->width($t) + 20;
	my $h = $fm->height() * 2;
	my $pmx = $self->width()/2 - $w/2;
	my $pmy = $self->height()/2 - $h/2;

	my $pm = new QPixmap($w, $h);
	$pm->fill($self, $pmx, $pmy);

	$p = new QPainter;
	my $x = 10;
	my $y = $h/2 + $fm->descent();
	my $i = 0;
	$p->begin($pm);
	$p->setFont($self->font());
	my $i16;
	my $index = 0;
	my $length = length($t);
	while($index < $length) {
	    $_ = substr($t, $index++, 1);
	    $i16 = ($$self{'b'}+$i) & 15;
	    $p->setPen(new QColor((15-$i16)*16, 255, 255, $Spec{Hsv}));
	    $p->drawText($x, $y-$sin_tbl[$i16]*$h/800, substr($t, $i), 1);
	    $x += $fm->width($_);
	    $i++;
	}
	$p->end();

	$self->bitBlt($pmx, $pmy, $pm);
    }
}
