use Test::More tests => 4;
use lib qw(lib ../lib t/test124);
use Su base => './t/test124';

my $su = Su->new;

my $ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

my $obj = $su->retr('main');

ok($obj);

ok( $obj->{model} );

# Access to the global field.
is( $obj->{model}->{g_debug}, "true" );
