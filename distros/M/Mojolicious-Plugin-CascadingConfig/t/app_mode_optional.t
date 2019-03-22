use strict;
use utf8;
use Test::Mojo;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('qa'); # this file does not exist
lives_ok { $t->app->plugin('CascadingConfig') } 'production and development config files should load successfully';

is $t->app->config->{foo}, 'not_bar', 'foo value from development config file';
is_deeply $t->app->config->{baz}, ['♥'], 'baz value from production config file';
is $t->app->config->{music_dir}, 'music', 'music_dir value from production config file';

done_testing;
