use Test::More tests => 202;

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new( handler => sub {} ), "new parser" );

#diag( $s3->dump );

my $r = 0;
while ( $r < 100 ) {
    ok( $r += $s3->parse("t/test.html"), "parse HTML" );

    #diag("r = $r");
}
while ( $r < 200 ) {
    ok( $r += $s3->parse("t/test.xml"), "parse XML" );

    #diag("r = $r");
}
