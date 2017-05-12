#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use Try::Tiny;
use Prancer::Core;
use Prancer::Plugin::Database ();

# we are going to undef the Prancer::Core singleton over and over again
no strict 'refs';

# test getting back a single handle
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Database::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/single.yml');
    my $plugin = Prancer::Plugin::Database->load();

    my $conn1 = $plugin->database();
    ok($conn1);
    isa_ok($conn1, 'DBI::db');

    my $conn2 = $plugin->database();
    ok($conn2);
    isa_ok($conn2, 'DBI::db');
    is($conn1, $conn2);

    my $conn3 = $plugin->database('default');
    ok($conn3);
    isa_ok($conn3, 'DBI::db');
    is($conn1, $conn3);
}

# test multiple handles in the config file and make sure they aren't getting
# mixed up.
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Database::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/multiple.yml');
    my $plugin = Prancer::Plugin::Database->load();

    try {
        my $conn = $plugin->database();
        fail('no default database defined');
    } catch {
        pass('no default database defined');
    };

    my $conn1 = $plugin->database('olap');
    ok($conn1);
    isa_ok($conn1, 'DBI::db');

    my $conn2 = $plugin->database('warehouse');
    ok($conn2);
    isa_ok($conn2, 'DBI::db');

    isnt($conn1, $conn2);
}

# what happens when one is named "default" but there exists more than one
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Database::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/multiple-default.yml');
    my $plugin = Prancer::Plugin::Database->load();

    my $conn1 = $plugin->database();
    ok($conn1);
    isa_ok($conn1, 'DBI::db');

    my $conn2 = $plugin->database('default');
    ok($conn2);
    isa_ok($conn2, 'DBI::db');

    is($conn1, $conn2);

    my $conn3 = $plugin->database('warehouse');
    ok($conn3);
    isa_ok($conn3, 'DBI::db');

    isnt($conn1, $conn3);
}

# if we make a connection in one place can we access it in another?
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Database::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/single.yml');
    my $plugin = Prancer::Plugin::Database->load();

    my $conn1 = undef;
    {
        $conn1 = $plugin->database();
        ok($conn1);
    }

    my $conn2 = undef;
    {
        $conn2 = $plugin->database();
        ok($conn2);
    }

    is($conn1, $conn2);
}

# again, if we make multiple connections from different places are they the same
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Database::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/single.yml');

    my $conn1 = undef;
    {
        my $plugin = Prancer::Plugin::Database->load();
        $conn1 = $plugin->database();
        ok($conn1);
    }

    my $conn2 = undef;
    {
        my $plugin = Prancer::Plugin::Database->load();
        $conn2 = $plugin->database();
        ok($conn2);
    }

    is($conn1, $conn2);
}

done_testing();
