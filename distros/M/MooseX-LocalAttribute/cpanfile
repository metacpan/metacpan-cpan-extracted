use strict;
use warnings;

on 'runtime' => sub {
    requires 'perl' => '5.008';
    requires 'Exporter';
    requires 'Scope::Guard';
};

on 'test' => sub {
    requires 'FindBin';
    requires 'Test::Exception';
    requires 'Test::More';
    requires 'Test::Requires';
    recommends 'Class::Accessor';
    recommends 'Mo';
    recommends 'Moo';
    recommends 'Moose';
    recommends 'Mouse';
    recommends 'Util::H2O';
    suggests 'Mojolicious';
    suggests 'Object::Pad';
};
