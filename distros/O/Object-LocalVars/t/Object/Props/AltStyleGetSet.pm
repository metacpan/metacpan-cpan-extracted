package t::Object::Props::AltStyleGetSet;
use strict;
use warnings;
use Object::LocalVars;
BEGIN {
    Object::LocalVars->accessor_style( {
        get => 'grab',
        set => 'hurl',
    });
}

our $name : Pub;
our $color : Pub;

1;
