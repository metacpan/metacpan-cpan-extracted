use Test::More tests => 5;
use lib qw(lib ../lib t/test121);
use Su base => './t/test121';

my $su = Su->new;

# Test for static call.
my $ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

$Su::MODEL_KEY_PREFIX->{pkg::Model} = 'pre';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'pre_val' );

$Su::MODEL_KEY_PREFIX->{pkg::Model}  = '';
$Su::MODEL_KEY_POSTFIX->{pkg::Model} = 'post';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'post_val' );

$Su::MODEL_KEY_PREFIX->{pkg::Model}  = 'pre';
$Su::MODEL_KEY_POSTFIX->{pkg::Model} = 'post';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'pre_post_val' );

$Su::MODEL_KEY_PREFIX->{pkg::Model}  = '';
$Su::MODEL_KEY_POSTFIX->{pkg::Model} = '';

$ret = $su->resolve( 'main', 'key1' );

is( $ret, 'value1' );

