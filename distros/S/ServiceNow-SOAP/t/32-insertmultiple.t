use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;
# SOAP::Lite->import(+trace => 'debug');

if (TestUtil::config) {
    if (getProp('test_insert_multiple')) {
        plan tests => 3;
    }
    else {
        plan skip_all => "test_insert_multiple is false";
    }
}
else {
    plan skip_all => "no config";
}

my $timestamp = TestUtil::getTimestamp();
my $lorem = TestUtil::lorem();

my $groupName = getProp('group_name');
ok ($groupName, "assignment group is $groupName");
my $shortDescription = "Test $timestamp script $0";
my $fullDescription = "$lorem\n$timestamp";

my $sn = TestUtil::getSession();
my $incident = $sn->table("incident");

my @allrecs;
for (my $i = 0; $i < 3; ++$i) {
    my $desc = "Test $timestamp multiple #$i";
    my $newrec = {
        short_description => $desc,
        assignment_group => $groupName,
        description => $desc,
        impact => 3};
    push @allrecs, $newrec;
}

my @results = $incident->insertMultiple(@allrecs);
my $count = @results;
ok ($count == 3, "$count records inserted");

my $good = 0;
foreach my $result (@results) {
    note $result->{number}, " ", $result->{sys_id};
    $good++ if isGUID($result->{sys_id});
}

ok ($good == 3, "$good results look good");
1;
