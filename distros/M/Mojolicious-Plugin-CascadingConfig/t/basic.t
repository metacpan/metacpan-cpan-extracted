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

is $t->app->config->{foo}, 'bar', 'foo value from production config file';
is_deeply $t->app->config->{baz}, ['♥'], 'baz value from production config file';
is $t->app->config->{music_dir}, 'music', 'music_dir value from production config file';

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('development');
$t->app->plugin('CascadingConfig');

is $t->app->config->{foo}, 'not_bar', 'foo value from development config file';
is_deeply $t->app->config->{baz}, ['♥'], 'baz value from production config file';
is $t->app->config->{music_dir}, 'music', 'music_dir value from production config file';

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('staging');
$t->app->plugin('CascadingConfig');

is $t->app->config->{foo}, 'not_bar', 'foo value from development config file';
is_deeply $t->app->config->{baz}, ['♫'], 'baz value from staging config file';
is $t->app->config->{music_dir}, 'music', 'music_dir value from production config file';

done_testing;
