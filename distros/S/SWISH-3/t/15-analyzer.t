use Test::More tests => 3;

use SWISH::3;

ok( my $s3 = SWISH::3->new(), "new s3 object" );

#ok( my $analyzer = $s3->analyzer, "get analyzer" );

like( 'foo', $s3->analyzer->get_regex, 'get regex' );

ok( $s3->tokenize('foo bar baz'), "tokenize" );

