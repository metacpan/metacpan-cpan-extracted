#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use lib 't';
{
    package Foo;

    use Test::Exception;

    use ContainedWRole;
    use MooX::Attributes::Shadow ':all';


    throws_ok { ContainedWRole->shadow_attrs( fmt => sub { 'x' . shift }  ) }
        qr/really a Moo/, 'not Moo';


}

done_testing;
