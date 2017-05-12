#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
{

    package Foo;
    use base 'App::Cmd';

    package Bar;
    use Mouse;
    extends 'MouseX::App::Cmd';

}

is_deeply( \%{ Bar->new }, \%{ Foo->new }, 'Internal hashes match' );
