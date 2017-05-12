use Test::More tests => 4;

use_ok('SWISH::3');

#ok( my $s3 = SWISH::3->new( handler => sub { diag("got data: $_[0] ") } ),
ok( my $s3 = SWISH::3->new(), "new parser" );
ok( $s3->parse("t/test.html"), "parse HTML" );
ok( $s3->parse("t/test.xml"),  "parse XML" );

