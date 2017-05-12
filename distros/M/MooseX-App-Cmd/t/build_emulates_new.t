use strict;
use warnings;

use Test::More tests => 1;
{

    package Foo;
    use base 'App::Cmd';

    package Bar;
    use Moose;
    extends 'MooseX::App::Cmd';

}

is_deeply( \%{ Bar->new }, \%{ Foo->new }, 'Internal hashes match' );
