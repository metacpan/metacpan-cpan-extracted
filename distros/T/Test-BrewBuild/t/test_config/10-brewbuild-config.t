#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';

my $m = Mock::Sub->new;
my $set_plugin = $m->mock('Test::BrewBuild::_set_plugin');

{ # good conf file
    $ENV{BB_CONF} = "t/conf/bb-brewbuild.conf";

    my $bb = $mod->new;
    is ($bb->{args}{timeout}, 99, "config file timeout took");
    is ($bb->{args}{remove}, 1, "config file remove took");
    like ($bb->{args}{plugin}, qr/UnitTest/, "config file plugin took");
    is ($bb->{args}{save}, 1, "config file save took");
    is ($bb->{args}{debug}, 1, "config file debug took");
    is ($bb->{args}{legacy}, 1, "config file legacy took");

    $ENV{BB_CONF} = '';
}
{ # override the conf file with params

    $ENV{BB_CONF} = "t/conf/bb-brewbuild.conf";

    my $bb = $mod->new(
        timeout => 50,
        remove => 0,
        plugin => 'Test::BrewBuild::Plugin::TestAgainst',
        save => 0,
        debug => 3,
        legacy => 0,
    );

    is ($bb->{args}{timeout}, 50, "timeout override");
    is ($bb->{args}{remove}, 0, "remove override");
    like ($bb->{args}{plugin}, qr/TestAgainst/, "plugin override");
    is ($bb->{args}{save}, 0, "save override");
    is ($bb->{args}{debug}, 3, "debug override");
    is ($bb->{args}{legacy}, 0, "legacy override");

    $ENV{BB_CONF} = '';
}
$set_plugin->unmock;

done_testing();
