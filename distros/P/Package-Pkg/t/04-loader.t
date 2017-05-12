use strict;
use warnings;

use Test::Most 'no_plan';

use Package::Pkg;

my ( $loader );
$loader = Package::Pkg->loader(qw/ Apple Banana::Cherry /);

is( $loader->load( 'p0' ), 'Apple::p0' );
is( $loader->load( 'p1' ), 'Banana::Cherry::p1' );
is( $loader->load(qw/ p0 p1 /), 'Apple::p0::p1' );

package Apple::p0;

sub p0 {}

package Banana::Cherry::p1;

sub p1 {}

package Apple::p0::p1;

sub p0p1 {}

