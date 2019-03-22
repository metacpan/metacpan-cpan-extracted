use strict;
use utf8;
use Test::Mojo;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('production');
$t->app->plugin('CascadingConfig');

ok !$t->app->config->{config_override}, 'no override';
is $t->app->config->{foo}, 'bar', 'foo value from config file';
is_deeply $t->app->config->{baz}, ['♥'], 'baz value from config file';
is $t->app->config->{music_dir}, 'music', 'music_dir value from config file';

$t = Test::Mojo->new('MojoliciousTest', {foo => 'pub'});
$t->app->moniker('myapp');
$t->app->mode('production');
$t->app->plugin('CascadingConfig');

ok $t->app->config->{config_override}, 'override';
is $t->app->config->{foo}, 'pub', 'override value';
ok !exists $t->app->config->{baz}, 'baz does not exist';
ok !exists $t->app->config->{music_dir}, 'music_dir does not exist';

# mode shouldn't matter
$t = Test::Mojo->new('MojoliciousTest', {foo => 'pub'});
$t->app->moniker('myapp');
$t->app->mode('development');
$t->app->plugin('CascadingConfig');

ok $t->app->config->{config_override}, 'override';
is $t->app->config->{foo}, 'pub', 'override value';
ok !exists $t->app->config->{baz}, 'baz does not exist';
ok !exists $t->app->config->{music_dir}, 'music_dir does not exist';

done_testing;
