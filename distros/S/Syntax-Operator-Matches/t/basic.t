use Test2::V0;

use Syntax::Operator::Matches;

ok( undef matches undef );
ok( not 1 matches undef );
ok( 'foo' matches qr/FOO/i );
ok( 'foo' matches 'foo' );
ok( 'foo' matches [ 'fool', 'foo' ] );
ok( not 'foo' matches 'bar' );

done_testing;
