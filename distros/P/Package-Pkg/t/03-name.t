use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Package::Pkg;

is( pkg->name(qw/ A B C D E F /), 'A::B::C::D::E::F' );
is( pkg->name(qw/ A::B C:::D E::::F /), 'A::B::C::D::E::F' );
is( pkg->name( 'A::' ), 'A::' );
is( pkg->name( '::A' ), 'main::A' );
is( pkg->name( '::' ), '' );

is( pkg->name( 'Xy', 'A::', '::B' ), 'Xy::A::B' );
is( pkg->name( 'Xy', 'A::' ), 'Xy::A::' );

{
    package Zy;

    use Test::Most;
    use Package::Pkg;

    is( pkg->name( '::', 'A::', '::B' ), 'Zy::A::B' );
    is( pkg->name( '::Xy::A::B' ), 'Zy::Xy::A::B' );
}

my $zy = bless {}, 'Zy';

is( pkg->name( $zy, 'A::', '::B' ), 'Zy::A::B' );
is( pkg->name( $zy, 'Xy::A::B' ), 'Zy::Xy::A::B' );
is( pkg->name( $zy, 'Xy::A::B', {} ), 'Zy::Xy::A::B::HASH' );


