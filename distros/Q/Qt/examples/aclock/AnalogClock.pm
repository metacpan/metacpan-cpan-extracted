#
# PerlQt Example Widget: AnalogClock (AnalogClock.pm)
#
# Implementation of AnalogClock widget.
#
# The AnalogClock widget uses a QTimer object to redraw the clock
# every 5 seconds.  The advantage of QTimers over standard timer
# events is that QTimer emits a signal when the timer is activated.
# The DigitalClock (dclock) example uses standard timer events.
#

package AnalogClock;

use QObject;
use QPainter;
use QTimer;
use QWidget;

use slots 'timeout()';

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(@_);

    $$self{'time'} = [ localtime ];
    $internalTimer = new QTimer($self);
    $self->connect($internalTimer, 'timeout()', 'timeout()');
    $internalTimer->start(5000);

    return $self
}

sub timeout {
    my $self = shift;

    $self->update() if (localtime)[1] != $$self{'time'}[1];
}

sub pause {
    print shift;
    <STDIN>;
}

sub paintEvent {
    my $self = shift;

    return unless $self->isVisible();
    $$self{'time'} = [ localtime ];

    my $pts = new QPointArray;
    my $paint = new QPainter;
    $paint->begin($self);
    $paint->setBrush($self->foregroundColor());

    my $cp = $self->rect()->center();
    my $d = ($self->width() < $self->height()) ?
	$self->width() : $self->height();

    my $matrix = new QWMatrix;
    $matrix->translate($cp->x(), $cp->y());
    $matrix->scale($d/1000.0, $d/1000.0);

    my $h_angle = 30*($$self{'time'}[2]%12-3) + $$self{'time'}[1]/2;
    $matrix->rotate($h_angle);
    $paint->setWorldMatrix($matrix);
    $pts->setPoints(-20,0, 0,-20, 300,0, 0,20);
    $paint->drawPolygon($pts);
    $matrix->rotate(-$h_angle);

    my $m_angle = ($$self{'time'}[1]-15)*6;
    $matrix->rotate($m_angle);
    $paint->setWorldMatrix($matrix);
    $pts->setPoints(-10,0, 0,-10, 400,0, 0,10);
    $paint->drawPolygon($pts);
    $matrix->rotate(-$m_angle);

    for(my $i = 0; $i < 12; $i++) {
	$paint->setWorldMatrix($matrix);
	$paint->drawLine(450,0, 500,0);
	$matrix->rotate(30);
    }
    $paint->end();
}
