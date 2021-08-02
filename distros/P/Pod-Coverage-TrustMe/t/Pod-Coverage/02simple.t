use strict;
use warnings;
use Test::More;
use lib 't/Pod-Coverage/lib';

use Pod::Coverage::TrustMe;

my $obj = Pod::Coverage::TrustMe->new(package => 'Simple1');

is( $obj->coverage, 2/3, "Simple1 has 2/3rds coverage");

$obj = Pod::Coverage::TrustMe->new(package => 'Simple2');

is( $obj->coverage, 0.75, "Simple2 has 75% coverage");

ok( eq_array([ $obj->naked ], [ 'naked' ]), "naked isn't covered");

ok( eq_array([ $obj->naked ], [ $obj->uncovered ]), "naked is uncovered");

$obj = Pod::Coverage::TrustMe->new(package => 'Simple2', private => [ 'naked' ]);

is ( $obj->coverage, 1, "nakedness is a private thing" );

$obj = Pod::Coverage::TrustMe->new(package => 'Simple1', also_private => [ 'bar' ]);

is ( $obj->coverage, 1, "it's also a private bar" );

is_deeply ( [ sort $obj->covered ], [ 'baz', 'foo' ], "those guys are covered" );

$obj = Pod::Coverage::TrustMe->new(package => 'Pod::Coverage::TrustMe');

is( $obj->coverage, 1, "Pod::Coverage::TrustMe is covered" );

$obj = Pod::Coverage::TrustMe->new(package => 'Simple3');

is( $obj->coverage, 1, 'Simple3 is covered' );

$obj = Pod::Coverage::TrustMe->new(package => 'Simple4');

is( $obj->coverage, 1, "External .pod grokked" );

$obj = Pod::Coverage::TrustMe->new(package => 'Simple5');

is( $obj->coverage, 1, "Multiple docs per item works" );

$obj = Pod::Coverage::TrustMe->new(package => "Simple6");

is( $obj->coverage, 1/3, "Simple6 is 2/3rds with no extra effort" );

$obj = Pod::Coverage::TrustMe->new(package => "Simple6", export_only => 1);

is( $obj->coverage, 1/2, "Simple6 is 50% if you only check exports" );

$obj = Pod::Coverage::TrustMe->new(package => "Simple8");

is( $obj->coverage,    undef, "can't deduce for Simple8" );
is( $obj->why_unrated, 'no public symbols defined', 'why is correct' );

$obj = Pod::Coverage::TrustMe->new(package => 'Simple9');

is($obj->coverage, undef, 'Simple9 has no coverage');
like($obj->why_unrated, qr/^requiring 'Simple9' failed/, 'why is correct');

$obj = Pod::Coverage::TrustMe->new( package => 'Earle' );
is( $obj->coverage, 1, "earle is covered" );
is( scalar $obj->covered, 2 );

$obj = Pod::Coverage::TrustMe->new( package => 'Args' );
is( $obj->coverage, 1, "Args is covered" );

$obj = Pod::Coverage::TrustMe->new( package => 'XS4ALL' );
is( $obj->coverage, 1, "XS4ALL is covered" );

$obj = Pod::Coverage::TrustMe->new( package => 'Fully::Qualified' );
is( $obj->coverage, 1, "Fully::Qualified is covered" );

done_testing;
