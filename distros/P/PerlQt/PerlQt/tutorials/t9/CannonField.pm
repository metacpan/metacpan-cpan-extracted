package CannonField;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::signals
	angleChanged => ['int'];
use Qt::slots
	setAngle => ['int'];
use Qt::attributes qw(
	ang
);
use POSIX qw(atan);

sub angle () { ang }

sub NEW {
    shift->SUPER::NEW(@_);

    ang = 45;
    setPalette(Qt::Palette(Qt::Color(250, 250, 200)));
}

sub setAngle {
    my $degrees = shift;
    $degrees = 5 if $degrees < 5;
    $degrees = 70 if $degrees > 70;
    return if ang == $degrees;
    ang = $degrees;
    repaint();
    emit angleChanged(ang);
}

sub paintEvent {
    my $p = Qt::Painter(this);
    $p->setBrush(&blue);
    $p->setPen(&NoPen);

    $p->translate(0, rect()->bottom);
    $p->drawPie(Qt::Rect(-35, -35, 70, 70), 0, 90*16);
    $p->rotate(- ang);
    $p->drawRect(Qt::Rect(33, -4, 15, 8));
}

sub sizePolicy {
    Qt::SizePolicy(&Qt::SizePolicy::Expanding, &Qt::SizePolicy::Expanding);
}

1;
