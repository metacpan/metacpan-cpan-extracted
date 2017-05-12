use strict;
use ServiceNow::SOAP;
use lib 't';
use TestUtil;
use Test::More;
if (TestUtil::config) { plan tests => 2 } 
else { plan skip_all => "no config" };

my $instance = TestUtil::getInstance();
my $user = TestUtil::getUsername();
BAIL_OUT "not initialized" unless $instance;
my $sn = ServiceNow($instance, $user, "bad password")->connect();
ok (!$sn, "connect trapped bad password");
ok ($@, '$@=\"' . $@ . '\"');

1;
