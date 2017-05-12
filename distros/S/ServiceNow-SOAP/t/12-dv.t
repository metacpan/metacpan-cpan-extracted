use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 9 } else { plan skip_all => "no config" };

my $sn = TestUtil::getSession();
my $sys_user = $sn->table("sys_user");

# Testing Display Values
my $groupName = TestUtil::config->{group_name};
my $sys_user_group = $sn->table("sys_user_group");
my $grpRec = $sys_user_group->getRecord(name => $groupName);
ok($grpRec, "sys_user_group record read");
my $grpId = $grpRec->{sys_id};
ok(TestUtil::isGUID($grpId), "Group sys_id=$grpId");
ok($grpRec->{name} eq $groupName, "Group name is $groupName");
my $grpMgrId = $grpRec->{manager};
ok(TestUtil::isGUID($grpMgrId), "Group manager sys_id=$grpMgrId");
my $grpMgrRec = $sys_user->get($grpMgrId);
my $grpMgrName = $grpMgrRec->{name};
ok($grpMgrName, "Group manager name=$grpMgrName");
my $grpRec2 = $sys_user_group->setDV("true")->get($grpId);
ok($grpRec2, "grpRec2 retrieved");
ok($grpRec2->{manager} eq $grpMgrName, "setDV('true')");
my $grpRec3 = $sys_user_group->setDV("all")->get($grpId);
ok($grpRec3->{dv_manager} eq $grpMgrName, "setDV('all')");
my $grpRec4 = $sys_user_group->setDV("")->get($grpId);
ok($grpRec4->{manager} eq $grpMgrId, "setDV('')");

1;
