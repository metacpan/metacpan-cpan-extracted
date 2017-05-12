use strict;
use warnings;
use Test::More;
use lib 't/lib';

plan tests => 3;

use_ok('TestApp');

my $app = TestApp->new;

ok($app->load_plugin('Bar'), "Loaded Bar");
ok(!$app->load_plugin('Bar'), "Didn't load Bar because we already had it");

