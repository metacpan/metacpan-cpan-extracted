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
    my $s = "Angle = " . ang;
    my $p = Qt::Painter(this);
    $p->drawText(200, 200, $s);
}

sub sizePolicy {
    Qt::SizePolicy(&Qt::SizePolicy::Expanding, &Qt::SizePolicy::Expanding);
}

1;
