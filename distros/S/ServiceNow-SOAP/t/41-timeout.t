use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use Time::HiRes;
use lib 't';
use TestUtil;

if (TestUtil::config) { 
    if (getProp("test_timeout")) { plan tests => 4 }
    else { plan skip_all => "timeout test disabled" }
} 
else { plan skip_all => "no config" };

my $sn = TestUtil::getSession();
my $tblname = "cmdb_ci";
my $tbl = $sn->table($tblname);
$tbl->setTimeout(20);
my $count = $tbl->count();
ok ($count > 1000, "$count records in $tblname");

my ($start, $elapsed);
my @keys;
$start = Time::HiRes::time();
eval { @keys = $tbl->getKeys() };
$elapsed = Time::HiRes::time() - $start;
printf "\nelapsed=%.2fs %s\n", $elapsed, $@;
ok ($@, "getKeys threw exception with 20 sec timeout");

$tbl->setTimeout(600);
$start = Time::HiRes::time();
eval { @keys = $tbl->getKeys() };
$elapsed = Time::HiRes::time() - $start;
printf "\nelapsed=%.2fs %s\n", $elapsed, $@;
ok (!$@, "no exception with 600 sec timeout");
print scalar(@keys), " keys retrieved\n";
ok (@keys == $count, scalar(@keys) . " keys retrieved, expected $count");

1;
