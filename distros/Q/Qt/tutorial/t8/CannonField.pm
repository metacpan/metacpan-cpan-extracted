package CannonField;

use Qt;
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
    my $self = shift;

    $self->drawText(200, 100, "Angle = $$self{'ang'}");
}
