#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

$ENV{BB_CONF} = "t/conf/brewbuild.conf";

my $d = Test::BrewBuild::Dispatch->new;

is (ref $d->{testers}, 'ARRAY', "testers is an array ref");
is ($d->{testers}[0], '127.0.0.1', "first tester ok");
is ($d->{testers}[1], '127.0.0.1:9999', "second tester ok");

is ($d->{repo}, "https://github.com/stevieb9/p5-test-brewbuild", "repo ok");

is ($d->{cmd}, "brewbuild -N", "cmd took ok");

$ENV{BB_CONF} = '';

$d = Test::BrewBuild::Dispatch->new;

is ($d->{testers}, undef, "testers empty if no cf file");
is ($d->{repo}, undef, "repo empty if no cf file");
is ($d->{cmd}, undef, "cmd empty if no cf file");

done_testing();
