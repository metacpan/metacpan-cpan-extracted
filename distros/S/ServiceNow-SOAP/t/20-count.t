use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { 
    if (getProp("test_aggregates")) { plan tests => 7 }
    else { plan skip_all => "aggregates disabled" }
} 
else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $computer = $sn->table('cmdb_ci_computer');
my $wsCount1 = $computer->count(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
ok ($wsCount1 > 0, "Workstation count = $wsCount1");
my $wsCount2 = $computer->count('sys_class_name=cmdb_ci_computer^operational_status=1');
ok ($wsCount2 == $wsCount2, "Count using encoded query");
my @wsKeys = $computer->getKeys(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
ok (@wsKeys == $wsCount1, "Workstation keys = $wsCount1");

my $emptyQuery = $computer->asQuery();
ok ($emptyQuery->getCount() == 0, "Empty query is empty");
my $wsQuery1 = $computer->asQuery(@wsKeys);
ok ($wsQuery1->getCount() == $wsCount1, "Query looks okay");
my $computerQuery = $computer->query();
ok ($computerQuery->getCount() > $wsCount1, "More computers than workstations");

my @wsRec1 = $computer->getRecords(sys_class_name => 'cmdb_ci_computer', operational_status => 1);
my $wsCount3 = @wsRec1;
ok ($wsCount3 < $wsCount1, "getRecords returned $wsCount3 computers");

1;
