package t::Object::Props::AltStyleGet;
use strict;
use warnings;
use Object::LocalVars;
BEGIN {
    Object::LocalVars->accessor_style( {
        get => 'grab',
    });
}

our $name : Pub;
our $color : Pub;

1;
