package t::Object::PropsOverload;
use strict;
use warnings;
use Object::LocalVars;
use overload (
    q{0+}   => sub { 0 },
    q{""}   => sub { "some object" },
    q{bool} => sub { 1 },
    fallback => 1,
);

our $name : Pub;
our $color : Pub;

1;
