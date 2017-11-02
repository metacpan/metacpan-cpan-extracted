#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;
use Mojolicious;

use lib 't/service-manage';

BEGIN {
  use_ok( 'T::Service' ) || print "Bail out!\n";
  use_ok( 'T::Services' ) || print "Bail out!\n";
  use_ok( 'T::Service::MyService' ) || print "Bail out!\n";
}

my $dbi = {dbi=>1};
my $models = {models=>1};

my $app = Mojolicious->new();

$app->plugin("Service",{
    namespaces=>["T::Service"],
    services_class=>"T::Services",
    dbi=>$dbi,
    models=>$models
  }
);

my $t1 = $app->service("my_service");

ok($t1->dbi == $dbi,"Service-dbi");
ok($t1->app == $app,"Service-app");
ok($t1->models == $models,"Service-models");
ok($t1->test1 eq "T::Service::test1", "Service-Test1");
ok($t1->test2 eq "T::Service::MyService::test2", "Service-Test2");

done_testing();
