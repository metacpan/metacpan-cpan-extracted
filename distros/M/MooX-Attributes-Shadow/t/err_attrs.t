#!perl

use Test2::V0;
use Test::Lib;

use Container1;

like( dies { Container1::run_shadow_attrs( attrs => 3 ) },  qr/invalid type/, 'bad attrs' );

like( dies { Container1->new->foo }, qr/must first be shadowed/, 'no attrs' );

like( dies { Container1::run_shadow_attrs( ); }, qr/must specify attrs/, 'bad attrs' );


done_testing;
