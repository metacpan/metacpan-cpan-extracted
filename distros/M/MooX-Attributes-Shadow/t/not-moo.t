#!perl

use Test2::V0;

use Test::Lib;

{
    package Foo;

    use Test2::V0;

    use ContainedWRole;
    use MooX::Attributes::Shadow ':all';


    like(
        dies {
            ContainedWRole->shadow_attrs( fmt => sub { 'x' . shift } )
        },
        qr/really a Moo/,
        'not Moo'
    );
}

done_testing;
