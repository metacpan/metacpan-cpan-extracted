#!perl -T

use Test::More tests => 29;


BEGIN{ use_ok ( 'MooseX::Types::Vehicle', qw/to_VIN17 is_VIN17/ ) }

ok ( is_VIN17('3D7KS28C26G180041'), "VALID VIN [2006 Ram]" );

ok ( !is_VIN17(' 3D7KS28C26G180041'), "NOT VALID VIN [2006 Ram (whitespace)]" );
ok ( !is_VIN17('3D7KS28C26G180041 '), "NOT VALID VIN [2006 Ram (whitespace)]" );
ok ( !is_VIN17('3D7KS28C 26G180041'), "NOT VALID VIN [2006 Ram (whitespace)]" );
ok ( !is_VIN17('3d7ks28c26g180041'), "NOT VALID VIN [Not a 2006 Ram (case)]" );
ok ( !is_VIN17('3D7KS28C26G18OO41'), "NOT VALID VIN [Not a 2006 Ram (0=O)]" );
ok ( !is_VIN17('3D7KS28C26G18004I'), "NOT VALID VIN [Not a 2006 Ram (1=I)]" );
ok ( !is_VIN17('3D7KS28C26G180042'), "NOT VALID VIN [Not a 2006 Ram (1=2 checksum)]" );

is ( to_VIN17(' 3D7KS28C26G180041'), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (whitespace)]" );
is ( to_VIN17('3D7KS28C26G180041 '), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (whitespace)]" );
is ( to_VIN17('3D7KS28C 26G180041'), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (whitespace)]" );
is ( to_VIN17('3d7ks28c26g180041'), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (case)]" );
is ( to_VIN17('3D7KS28C26G18OO41'), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (0=O)]" );
is ( to_VIN17('3D7KS28C26G18OO4I'), '3D7KS28C26G180041', "COERCION TO VALID VIN [2006 Ram (I=1)]" );
isnt ( to_VIN17('3D7KS28C26G18OO42'), '3D7KS28C26G180041', "FAILED COERCION VALID VIN [2006 Ram (checksum)]" );

ok ( is_VIN17( to_VIN17(' 3D7KS28C26G180041') ), "VALID VIN (after coercion) [2006 Ram (whitespace)]" );
ok ( is_VIN17( to_VIN17('3D7KS28C26G180041 ') ), "VALID VIN (after coercion) [2006 Ram (whitespace)]" );
ok ( is_VIN17( to_VIN17('3D7KS28C 26G180041') ), "VALID VIN (after coercion) [2006 Ram (whitespace)]" );
ok ( is_VIN17( to_VIN17('3d7ks28c26g180041') ), "VALID VIN (after coercion) [2006 Ram (case)]" );
ok ( is_VIN17( to_VIN17('3D7KS28C26G18OO41') ), "VALID VIN (after coercion) [2006 Ram (0=O)]" );
ok ( is_VIN17( to_VIN17('3D7KS28C26G18004I') ), "VALID VIN (after coercion) [2006 Ram (1=I)]" );
ok ( !is_VIN17( to_VIN17('3D7KS28C26G180042') ), "NOT VALID VIN (after coercion) [Not a 2006 Ram (checksum)]" );

# Self coercion
is ( to_VIN17('2G1FK3DJXB9198600'), '2G1FK3DJXB9198600', "NOOP-coercion" );

ok ( is_VIN17('2G1FK3DJXB9198600'), 'VALID VIN [2011 Camaro]' );
ok ( is_VIN17('1GKS2EEF1BR262285'), "VALID VIN [2011 Yukon]" );
ok ( is_VIN17('1GCSKTE3XAZ269885'), "VALID VIN [2010 Silverado]" );
ok ( is_VIN17('1J4AA5D19AL168179'), "VALID VIN [2010 Wrangler]" );
ok ( is_VIN17('3GNAL2EK3CS539671'), "VALID VIN [2010 Captiva]" );
