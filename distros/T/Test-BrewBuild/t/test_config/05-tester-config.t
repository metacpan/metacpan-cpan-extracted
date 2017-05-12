#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

{ # good conf file
    $ENV{BB_CONF} = "t/conf/brewbuild.conf";

    my $t = Test::BrewBuild::Tester->new;

    is ($t->ip, '127.0.0.1', "conf ip ok");
    is ($t->port, 7801, "conf port ok");

    $ENV{BB_CONF} = '';
}
{ # no conf file
    $ENV{BB_CONF} = "t/conf/brewbuild_no_tester.conf";

    my $t = Test::BrewBuild::Tester->new;

    is ($t->ip, '0.0.0.0', "ip ok no cf");
    is ($t->port, 7800, "port ok no cf");

    $ENV{BB_CONF} = '';
}
{ # manual
    $ENV{BB_CONF} = '';

    my $t = Test::BrewBuild::Tester->new;
    $t->ip('127.0.0.5');
    $t->port(8888);

    is ($t->ip, '127.0.0.5', "ip ok with ip()");
    is ($t->port, 8888, "port ok with port()");

}
done_testing();
