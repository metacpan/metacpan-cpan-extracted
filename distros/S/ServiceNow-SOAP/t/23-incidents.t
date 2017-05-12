use strict;
use warnings;
use Test::More;
use ServiceNow::SOAP;
use List::MoreUtils qw(uniq);
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 3 } 
else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $incident = $sn->table('incident');
my $sys_user_group = $sn->table('sys_user_group')->setDV('true');
my $filter = getProp('incident_filter');
note "filter=$filter";
my $count = $incident->count($filter);
ok ($count >= 50, "count($count) is at least 50");
ok ($count < 10000, "count($count) is less than 10000");

my @incRecs = $incident->query($filter)->fetchAll();
ok (@incRecs == $count, "$count records fetched");

my @grpKeys = uniq grep { !/^$/ } map { $_->{assignment_group} } @incRecs;
my @grpRecs = $sys_user_group->asQuery(@grpKeys)->fetchAll();

my $i = 0;
foreach my $grp (@grpRecs) {
    my $sysid = $grp->{sys_id};
    my $name = $grp->{name};
    my $mgr = $grp->{manager};
    note ++$i, ": $sysid $name : $mgr";
}

1;
