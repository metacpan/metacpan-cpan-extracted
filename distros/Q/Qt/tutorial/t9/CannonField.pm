package CannonField;

use Qt;
use QColor;
use QPainter;
use QPen;
use QWidget;

use signals 'angleChanged(int)';
use slots 'setAngle(int)';

@ISA = qw(QWidget);

sub new {
    my $self = shift->SUPER::new(@_);

    $$self{'ang'} = 45;
    return $self;
}

sub angle { return shift->{'ang'} }

sub setAngle {
    my $self = shift;
    my $degrees = shift;

    $degrees = 5 if $degrees < 5;
    $degrees = 70 if $degrees > 70;
    return if $$self{'ang'} == $degrees;
    $$self{'ang'} = $degrees;
    $self->repaint();
    emit $self->angleChanged($$self{'ang'});
}

sub paintEvent {
    my $self  = shift;
    my $p     = new QPainter;
    my $brush = new QBrush($blue);
    my $pen   = new QPen($PenStyle{NoPen});

    $p->begin($self);
    $p->setBrush($brush);
    $p->setPen($pen);

    $p->translate(0, $self->rect()->bottom());
    $p->drawPie(new QRect(-35, -35, 70, 70), 0, 90*16);
    $p->rotate(-$$self{'ang'});
    $p->drawRect(new QRect(33, -4, 15, 8));

    $p->end();
}
