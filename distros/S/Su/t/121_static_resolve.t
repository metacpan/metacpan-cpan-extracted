use Test::More tests => 5;
use lib qw(lib ../lib t/test121);
use Su base => './t/test121';

# Test for static call.
my $ret = Su::resolve( 'main', 'key1' );

is( $ret, 'value1' );

$ret = resolve( 'main', 'key1' );

is( $ret, 'value1' );

# Change the locale
$Su::MODEL_LOCALE = 'ja_JP';

$ret = resolve( 'main', 'key1' );

is( $ret, 'value1_jp' );

# Change the locale to default
$Su::MODEL_LOCALE = '';

$ret = resolve( 'main', 'key1' );

is( $ret, 'value1' );

# Change the locale to not exist locale. Default model should load.
$Su::MODEL_LOCALE = 'dmy_Locale';

$ret = resolve( 'main', 'key1' );

is( $ret, 'value1' );

