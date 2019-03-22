use strict;
use Test::Mojo;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('prod');

throws_ok
    { $t->app->plugin('CascadingConfig', { modes => ['dont_exist', 'dev', 'stage'] }) }
    qr/Configuration file ".*myapp.dont_exist\.conf" missing, maybe you need to create it\?.*/,
    q{throws when first config file doesn't exist};

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('stage');
throws_ok
    { $t->app->plugin('CascadingConfig', { modes => ['prod', 'dont_exist', 'stage'] }) }
    qr/Configuration file ".*myapp.dont_exist\.conf" missing, maybe you need to create it\?.*/,
    q{throws when second config file doesn't exist};

$t = Test::Mojo->new('MojoliciousTest');
$t->app->moniker('myapp');
$t->app->mode('stage');
throws_ok
    { $t->app->plugin('CascadingConfig', { modes => ['prod', 'dev', 'dont_exist'] }) }
    qr/Configuration file ".*myapp.dont_exist\.conf" missing, maybe you need to create it\?.*/,
    q{throws when third config file doesn't exist};

done_testing;
