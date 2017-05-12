package CannonField;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::signals
	angleChanged => ['int'],
	forceChanged => ['int'];
use Qt::slots
	setAngle => ['int'],
	setForce => ['int'];
use Qt::attributes qw(
	ang
	f
);
use POSIX qw(atan);

sub angle () { ang }
sub force () { f }

sub NEW {
    shift->SUPER::NEW(@_);

    ang = 45;
    f = 0;
    setPalette(Qt::Palette(Qt::Color(250, 250, 200)));
}

sub setAngle {
    my $degrees = shift;
    $degrees = 5 if $degrees < 5;
    $degrees = 70 if $degrees > 70;
    return if ang == $degrees;
    ang = $degrees;
    repaint(cannonRect(), 0);
    emit angleChanged(ang);
}

sub setForce {
    my $newton = shift;
    $newton = 0 if $newton < 0;
    return if f == $newton;
    f = $newton;
    emit forceChanged(f);
}

sub paintEvent {
    my $e = shift;
    return unless $e->rect->intersects(cannonRect());
    my $cr = cannonRect();
    my $pix = Qt::Pixmap($cr->size);
    $pix->fill(this, $cr->topLeft);

    my $p = Qt::Painter($pix);
    $p->setBrush(&blue);
    $p->setPen(&NoPen);
    $p->translate(0, $pix->height - 1);
    $p->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90*16);
    $p->rotate(- ang);
    $p->drawRect(Qt::Rect(33, -4, 15, 8));
    $p->end;

    $p->begin(this);
    $p->drawPixmap($cr->topLeft, $pix);
}

sub cannonRect {
    my $r = Qt::Rect(0, 0, 50, 50);
    $r->moveBottomLeft(rect()->bottomLeft);
    return $r;
}

sub sizePolicy {
    Qt::SizePolicy(&Qt::SizePolicy::Expanding, &Qt::SizePolicy::Expanding);
}

1;
