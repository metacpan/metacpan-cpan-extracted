# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Component-PluginManager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('POE::Component::PluginManager') };

#########################

# I don't really know yet how to write tests for POE programs,
# but ill add some plugin loading/unloading tests in here later on.
# especially important: check if Class::Unload works!

