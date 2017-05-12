package t::Object::Props::AltStyleSet;
use strict;
use warnings;
use Object::LocalVars;
BEGIN {
    Object::LocalVars->accessor_style( {
        set => 'hurl',
    });
}

our $name : Pub;
our $color : Pub;

1;
