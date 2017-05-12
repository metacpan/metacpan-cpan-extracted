use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;
use lib 't/lib';

use TestApp3;

{
    my $app = TestApp3->new;
    my $res;

    is(
        exception { $res = $app->load_plugin('Lives') },
        undef,
        'lived through successfully loading a class',
    );

    note "does roles: ", join(', ', map { $_->name } $app->meta->calculate_all_roles_with_inheritance );

    ok(exists $app->_plugin_loaded->{'Lives'}, 'Lives was added to loaded plugin list');
    ok($app->does('TestApp3::Plugin::Lives'), 'app has the Lives plugin applied');

    like(
        exception { $res = $app->load_plugin('Dies1') },
        qr/Failed to load /,
        'Failure to load a class results in an exception',
    );

    ok(!exists $app->_plugin_loaded->{'Dies1'}, 'Dies1 was not added to loaded plugin list');
    ok(!$app->does('TestApp3::Plugin::Dies1'), 'app does not have the Dies1 plugin applied');

    ok(exists $app->_plugin_loaded->{'Lives'}, 'Lives is still in the loaded plugin list');
    ok($app->does('TestApp3::Plugin::Lives'), 'app still has the Lives plugin applied');
}

{
    my $app = TestApp3->new;
    my $res;

    # note - it's key that we already tried to load Dies1 in an earlier test
    like(
        exception { $res = $app->load_plugin('Dies1') },
        qr/Failed to load /,
        'Failure to load a class again results in the right exception',
    );

    #$res = warning {$app->load_plugins('Dies2', 'Lives')};
    like(
        exception { $res = $app->load_plugins('Lives', 'Dies2') },
        qr/Failed to load /,
        'Failure to load any class in a list results in an exception',
    );
    note "does roles: ", join(', ', map { $_->name } $app->meta->calculate_all_roles_with_inheritance );

    ok(!exists $app->_plugin_loaded->{'Dies1'}, 'Dies1 was not added to loaded plugin list');
    ok(!$app->does('TestApp3::Plugin::Dies1'), 'app does not have the Dies1 plugin applied');

    ok(exists $app->_plugin_loaded->{'Lives'}, 'Lives was added to loaded plugin list');
    ok($app->does('TestApp3::Plugin::Lives'), 'app has the Lives plugin applied');

    ok(!exists $app->_plugin_loaded->{'Dies2'}, 'Dies2 was not added to loaded plugin list');
    ok(!$app->does('TestApp3::Plugin::Dies2'), 'app does not have the Dies2 plugin applied');
}

done_testing;
