#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;
use Mojolicious::Services;

use lib 't/service-manage';

BEGIN {
  use_ok( 'Service::T1' ) || print "Bail out!\n";
}

my $dbi = {dbi=>1};
my $app = {app=>1};
my $models = {models=>1};

my $sm = Mojolicious::Services->new({
    namespaces=>["Service"],
    dbi=>$dbi,
    app=>$app,
    models=>$models
  }
);

my $t1 = $sm->service("T1");

ok($t1->dbi == $dbi,"Service-dbi");
ok($t1->app == $app,"Service-app");
ok($t1->models == $models,"Service-models");
ok($t1->test eq "T1::test", "Service-Test");

done_testing();
