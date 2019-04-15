# NOTE: 
#  currently not in use anymore
#  - see PDLA::Func (in Lib/) and t/func.t
use Test::More skip_all => 'See PDLA::Func';
use PDLA::LiteF;

BEGIN {
    eval "use PDLA::Slatec;";
    plan skip_all => "PDLA::Slatec: '$@'" if $@;
}

plan tests => 11;

use strict;

eval "use PDLA::Interpolate::Slatec";

########### First test normal subclassing ###########

my $x   = sequence(float,10);
my $y   = $x*$x + 0.5;

my $obj = new PDLA::Interpolate::Slatec( x => $x, y => $y );

isa_ok $obj, 'PDLA::Interpolate';
is $obj->library, "Slatec";
is( $obj->status, 1 );

my ( $xi, $yi, $gi, $ans, $d );

$xi = sequence(float,5) + 2.3;
$yi = $obj->interpolate( $xi );
is( $obj->status, 1 );

$ans = $xi*$xi + 0.5;
$d   = abs( $ans - $yi );
ok( all $d <= 0.03 );

( $yi, $gi ) = $obj->interpolate( $xi );
is( $obj->status, 1 );

$ans = 2*$xi;
$d   = abs( $ans - $gi );
ok( all $d <= 0.04 );

# see how they cope with threading 
#
$y = cat( $x*$x+43.3, $x*$x*$x-23 );

$obj->set( x => $x, y => $y );
is( $obj->status, 1 );

$yi = $obj->interpolate( $xi );
is( $obj->status, 1 );
ok( (dims($yi) == 2) & ($yi->getdim(0) == $xi->getdim(0)) & ($yi->getdim(1) == 2) );

$ans = cat( $xi*$xi+43.3, $xi*$xi*$xi-23 );
$d   = abs( $ans - $yi );
ok( all $d <= 6 );
