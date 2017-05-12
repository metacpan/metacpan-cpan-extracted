package MyApp;

use Test::More tests => 201;

use base qw( SWISH::3 );

ok( my $parser = MyApp->new(
        config  => 't/t.conf',
        handler => sub {

            #print 'foo';  # print() causes err under Test, warn() doesn't...
            #warn 'foo';
        }
    ),
    "new object with config"
);

#diag($parser->dump);

my $loops = 0;
while ( $loops++ < 100 ) {
    ok( $r = $parser->parse('t/test.html'), "parse HTML filesystem" );
    ok( $r = $parser->parse('t/test.xml'),  "parse XML filesystem" );
}
