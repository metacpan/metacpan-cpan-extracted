package Foo::SubChild;

use Moose;
extends 'Foo::Child';

__PACKAGE__->add_attributes(tribe=>{isa=>'Str'});

1;
