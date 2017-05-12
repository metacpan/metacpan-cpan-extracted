package t::Object::Props::AltStyleSame;
use strict;
use warnings;
use Object::LocalVars;
BEGIN {
    Object::LocalVars->accessor_style( {
        get => q{},
        set => q{},
    });
}

our $name : Pub;
our $color : Pub;

1;
