#!perl

use FindBin::libs;
use Test::More;

use XT::Business;
use Data::Dump qw/pp/;

# from Module::Pluggable
can_ok('XT::Business','plugins');

can_ok('XT::Business','plugin');
can_ok('XT::Business','find');
can_ok('XT::Business','call');

# no need for this
#can_ok('XT::Business','search_path');
#test_plugins();
test_plugin();
test_find();
test_call();

done_testing;

sub test_plugins {
    note "foo";
    my $rv = XT::Business->plugins;
    note ref($rv);
    isa_ok($rv,'ARRAY',
        'plugins returns array of module names');
    
}

sub test_plugin {
    my @all = XT::Business->plugin;
    note "map ". pp(\@all);
    is(scalar @all, 1,
        'found one plugin');

    is(XT::Business->plugin('Bar'), 'XT::Business::Plugin::Bar',
        'module name matches');
}
sub test_find {
    isa_ok(XT::Business->find('Bar'),'XT::Business::Plugin::Bar',
        'Bar matches');
}
sub test_call {
}
