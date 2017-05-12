use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use Time::HiRes;
use lib 't';
use TestUtil;

plan skip_all => "no config" unless TestUtil::config;
plan skip_all => "big query skipped" unless TestUtil::getProp("big_query");
plan tests => 2;

my $sn = TestUtil::getSession();
my $tblname = "cmdb_ci";
my $tbl = $sn->table($tblname);
my $count = $tbl->count();
ok ($count > 1000, "$count records in $tblname");

my $size = 100000;
$size = 100 * (int $count / 4 / 100) if ($size > $count);
note "size = $size";
$sn->set(query => $size);

my $query = $tbl->query();
ok ($query->getCount() == $count, "query count matches");

1;
