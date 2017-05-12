use strict;
use ServiceNow::SOAP;
use lib 't';
use TestUtil;
use Test::More;
if (TestUtil::config) { plan tests => 7 } 
else { plan skip_all => "no config" };

my $instance = TestUtil::getInstance();
my $user = TestUtil::getUsername();
my $pass = 'password';
BAIL_OUT "not initialized" unless $instance;
eval { my $sn = ServiceNow($instance, $user, $pass, qqery => 7) };
ok ($@, "bad option trapped");
eval { my $sn = ServiceNow($instance, $user, $pass, fetch => 0) };
ok ($@, "0 fetch trapped");

my $sn;
$sn = ServiceNow($instance, $user, $pass);
ok (!$sn->{trace}, "Trace is false");
$sn = ServiceNow($instance, $user, $pass, trace => 1);
ok ($sn->{trace}, "Trace is true");
$sn = ServiceNow($instance, $user, $pass, fetch => 100, query => 100000);
ok ($sn->{fetch} == 100, "Fetch is 100");
ok ($sn->{query} == 100000, "Query is 100000");
$sn->set(query => 5000);
ok ($sn->{query} == 5000, "Query is 100000");
1;
