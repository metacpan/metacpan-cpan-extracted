use strict;
use Test::More;
use ServiceNow::SOAP;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 8 } 
else { plan skip_all => "no config" };
my $instance = TestUtil::config->{instance};
my $user = TestUtil::config->{username};
my $pass = TestUtil::config->{password};
BAIL_OUT "not initialized" unless $instance;

my $sn = ServiceNow($instance, $user, $pass, trace => 1)->connect()
    or BAIL_OUT "Unable to connect";
ok ($sn, "connection successful");
my $sys_user = $sn->table("sys_user");
ok ($sys_user, "table method appears to work");
my $userrec = $sys_user->getRecord(user_name => $user);
ok($userrec, "User record retrieved");
my $usersysid = $userrec->{sys_id};
my $timezone = $userrec->{time_zone};
ok ($userrec->{user_name} eq $user, "User name is $user");
ok ($usersysid =~ /^[0-9a-z]{32}$/, "sys_id looks like a sys_id");
ok ($userrec->{time_zone} eq "GMT", "Time zone is GMT");

my $userrec2 = $sys_user->get($usersysid);
ok ($userrec2->{user_name} eq $user, "get method appears to work");

my $userrec3 = $sys_user->get('12345678901234567890123456789012');
ok (!$userrec3, "get method for bad sys_id returned null");

1;
