use Test::More tests => 102;

use_ok('SWISH::3');

ok( my $parser = SWISH::3->new( handler => sub { } ), "new parser" );

my $r = 0;
while ( $r < 100 ) {
    ok( $r += $parser->parse("t/latin1.xml"), "parse latin1 XML" );

    #diag("r = $r");
}
