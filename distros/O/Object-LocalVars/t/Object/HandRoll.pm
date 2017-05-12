package t::Object::HandRoll;
use strict;
use warnings;

sub new { 
    return bless {}, shift;
}

sub name {
    return $_[0]->{name};
}
sub set_name {
    $_[0]->{name} = $_[1];
    return $_[0];
}

sub color {
    return $_[0]->{color};
}
sub set_color {
    $_[0]->{color} = $_[1];
    return $_[0];
}

sub desc {
    my $self = shift;
    return "I'm " . $self->name . " and my color is " . $self->color;
};

sub report_caller {
    return ( caller );
}

sub report_package  {
    return __PACKAGE__
}

sub report_color {
    my $self = shift;
    return $self->color;
}

1;
