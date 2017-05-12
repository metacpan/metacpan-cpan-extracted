#!perl -w

use strict;
use Test::More;

BEGIN{
    @MouseX::YAML::Modules = qw(YAML::Syck);

    eval{ require MouseX::YAML }
        or plan skip_all => 'This is a test using YAML::Syck';
}

is(MouseX::YAML->backend, 'YAML::Syck', 'the backend is YAML::Syck');

do 't/01_basic.t';
die $@ if $@;
