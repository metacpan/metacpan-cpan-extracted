package t::Object::HandRoll::Sub;
use strict;
use warnings;
use Object::LocalVars;
Object::LocalVars->base_object( 't::Object::HandRoll' );

give_methods our $self;

our $color : Pub; # overrides super class definition -- dangerous
our $shape : Pub;

sub desc : Method {
    return "I'm " . $self->name . 
           ", my color is " . $self->color .
           " and my shape is $shape";
};

sub can_roll : Method {
    return $shape eq "circle" ? 1 : 0;
}

1;
