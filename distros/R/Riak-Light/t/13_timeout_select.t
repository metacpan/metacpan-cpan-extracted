use Test::More tests => 2;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout qw(test_timeout test_normal_wait);

test_timeout('Riak::Light::Timeout::Select');
test_normal_wait('Riak::Light::Timeout::Select');
