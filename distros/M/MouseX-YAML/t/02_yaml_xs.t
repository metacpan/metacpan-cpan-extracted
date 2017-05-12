#!perl -w

use strict;
use Test::More;

BEGIN{
    @MouseX::YAML::Modules = qw(YAML::XS);

    eval{ require MouseX::YAML }
        or plan skip_all => 'This is a test using YAML::XS';
}

is(MouseX::YAML->backend, 'YAML::XS', 'the backend is YAML::XS');

do 't/01_basic.t';

die $@ if $@;
