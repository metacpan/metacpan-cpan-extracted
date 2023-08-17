use Test2::V0;

use Syntax::Operator::Matches -all;

ok( not undef mismatches undef );
ok( 1 mismatches undef );
ok( not 'foo' mismatches qr/FOO/i );
ok( not 'foo' mismatches 'foo' );
ok( not 'foo' mismatches [ 'fool', 'foo' ] );
ok( 'foo' mismatches 'bar' );

done_testing;
