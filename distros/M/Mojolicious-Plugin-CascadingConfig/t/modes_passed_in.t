use strict;
use utf8;
use Test::Mojo;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('prod');
$t->app->plugin('CascadingConfig', { modes => ['prod', 'dev', 'stage'] });

is $t->app->config->{foo}, 'tavern', 'foo value from prod config file';
is_deeply $t->app->config->{baz}, ['♪'], 'baz value from prod config file';
is $t->app->config->{music_dir}, 'oldies', 'music_dir value from prod config file';

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('dev');
$t->app->plugin('CascadingConfig', { modes => ['prod', 'dev', 'stage'] });

is $t->app->config->{foo}, 'not_tavern', 'foo value from dev config file';
is_deeply $t->app->config->{baz}, ['♪'], 'baz value from prod config file';
is $t->app->config->{music_dir}, 'oldies', 'music_dir value from prod config file';

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('stage');
$t->app->plugin('CascadingConfig', { modes => ['prod', 'dev', 'stage'] });

is $t->app->config->{foo}, 'not_tavern', 'foo value from dev config file';
is_deeply $t->app->config->{baz}, ['stage'], 'baz value from stage config file';
is $t->app->config->{music_dir}, 'oldies', 'music_dir value from production config file';

done_testing;
