#!perl -w

use strict;
use Test::More;

BEGIN{
    @MouseX::YAML::Modules = qw(YAML);

    eval{ require MouseX::YAML }
        or plan skip_all => 'This is a test using YAML';
}

is(MouseX::YAML->backend, 'YAML', 'the backend is YAML');

do 't/01_basic.t';
die $@ if $@;
