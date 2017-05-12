use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

# SOAP::Lite->import(+trace => 'debug');

plan skip_all => "no config" unless TestUtil::config;
plan skip_all => "aggregates disabled" unless TestUtil::getProp("test_aggregates");

my $sn = TestUtil::getSession();
my $incident = $sn->table('incident');
my $sys_user_group = $sn->table('sys_user_group');
my $filter = getProp('incident_filter');
$filter = "$filter^assignment_group!=";
note "filter=$filter";

my $totalCount = $incident->count($filter);
ok ($totalCount > 0, "total count=$totalCount");

eval { my %badResult = $incident->countBy() };
ok ($@, "countBy failed with missing argument");
ok ($@, "message: $@");

my %byCategory = $incident->countBy('category', $filter);
ok (%byCategory, "byCategory not empty");
my $categoryKeys = keys %byCategory;
ok ($categoryKeys > 1, "$categoryKeys keys in byCategory");
foreach my $key (sort keys %byCategory) {
    my $count = $byCategory{$key};
    ok ($count =~ /\d+/, "category: $key: count=$count");
}

note "group by assignment_group (sys_id)";
my %byGrp1 = $incident->countBy('assignment_group', $filter);
my $grp1Keys = keys %byGrp1;
ok ($grp1Keys > 1, "$grp1Keys keys in byGrp1");

foreach my $key (sort keys %byGrp1) {
    my $count = $byGrp1{$key};
    ok ($count =~ /\d+/, "group: \"$key\": count=$count");
}

my $grpQry = $sys_user_group->asQuery(grep !/^$/, keys %byGrp1);
my $qCnt = $grpQry->getCount();
# ok($qCnt == $grp1Keys ||
#    ($qCnt + 1) == $grp1Keys, "query keys matches");
ok($qCnt == $grp1Keys, "query keys matches");
my @grpRecs = $grpQry->fetchAll();
my %grpHash = map { $_->{sys_id} => $_ } @grpRecs;

note "group by assignment_group (display value)";
$incident->setDV(1);
my %byGrp2 = $incident->countBy('assignment_group', $filter);
my $grp2Keys = keys %byGrp2;
ok ($grp2Keys > 1, "$grp2Keys keys in byGrp2");
foreach my $key (sort keys %byGrp1) {
    my $count1 = $byGrp1{$key};
    my $name = $key ? $grpHash{$key}->{name} : '';
    my $count2 = $byGrp2{$name};
    ok ($count1 == $count2, "group \"$name\": count=$count2");
}

done_testing;

1;
