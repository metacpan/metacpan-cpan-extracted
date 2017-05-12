use Test::More tests => 6;
use lib qw(lib ../lib t/test121);
use Su base => './t/test121';

my $su = Su->new;

# Test for static call.
my $ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

# Change the locale
$Su::MODEL_LOCALE = 'ja_JP';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1_jp' );

# Change the locale to default
$Su::MODEL_LOCALE = '';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

# Change the locale to not exist locale. Default model should load.
$Su::MODEL_LOCALE = 'dmy_Locale';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

my $su2 = Su->new;
$ret = $su->resolve( 'resource', 'key1' );
is( $ret, 'value1' );

