use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Package::Pkg;

is( pkg->package(qw/ A B C D E F /), 'A::B::C::D::E::F' );
is( pkg->package(qw/ A::B C:::D E::::F /), 'A::B::C::D::E::F' );
is( pkg->package( 'A::' ), 'A::' );
is( pkg->package( '::A' ), 'main::A' );
is( pkg->package( '::' ), '' );

is( pkg->package( 'Xy', 'A::', '::B' ), 'Xy::A::B' );
is( pkg->package( 'Xy', 'A::' ), 'Xy::A::' );

{
    package Zy;

    use Test::Most;
    use Package::Pkg;

    is( pkg->package( '::', 'A::', '::B' ), 'Zy::A::B' );
    is( pkg->package( '::Xy::A::B' ), 'Zy::Xy::A::B' );
}

my $zy = bless {}, 'Zy';

is( pkg->package( $zy, 'A::', '::B' ), 'Zy::A::B' );
is( pkg->package( $zy, 'Xy::A::B' ), 'Zy::Xy::A::B' );
is( pkg->package( $zy, 'Xy::A::B', {} ), 'Zy::Xy::A::B::HASH' );

