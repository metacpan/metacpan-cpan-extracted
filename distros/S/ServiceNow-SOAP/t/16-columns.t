use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

unless (TestUtil::config) { plan skip_all => "no config" };

my $tablename = "sys_user_group";
my $include = "sys_id,name,sys_updated_on";

my $sn = TestUtil::getSession();
my $tbl = $sn->table($tablename);

my $nincl = split /,/, $include;
ok ($nincl, "$nincl columns to be included");

my @cols = $tbl->columns();
my $ncol = scalar(@cols);
ok ($ncol, "$ncol columns in $tablename");

my $excl = $tbl->except($include);
my @excl = split /,/, $excl;
my $nexcl = scalar(@excl);

ok ($nexcl, "$nexcl columns to be excluded");
ok ($nexcl + $nincl == $ncol, "number add up");

my $qry = $tbl->query(active => "true", __order_by => "name");
$qry->include("sys_id,name,sys_updated_on");

my @recs = $qry->fetch();
my $count = @recs;
ok ($count > 5, "$count groups retrieved");
my $grp = $recs[0];
ok ($grp->{"sys_id"}, "sys_id found");
ok ($grp->{"sys_updated_on"}, "sys_updated_on found");
ok (!$grp->{"sys_created_on"}, "sys_created_on not found");

done_testing();
1;
