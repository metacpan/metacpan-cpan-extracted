use strict;
use warnings;
use Test::More;

eval "use Test::Cmd";
plan skip_all => 'Test::Cmd required' if $@;
eval "use Monitoring::Config";
plan skip_all => 'Monitoring::Config required' if $@;
plan tests    => 12;

use lib('t');
use TestUtils;

TestUtils::test_montt('t/data/209-service_post_processing');
