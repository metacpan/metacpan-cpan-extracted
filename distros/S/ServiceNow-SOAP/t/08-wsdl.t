use strict;
use warnings;
use Test::More;
use ServiceNow::SOAP;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;
use lib 't';
use TestUtil;

unless (TestUtil::config) { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $tablename = 'incident';
my $tbl = $sn->table($tablename);

my @columns = $tbl->columns();
my $count = @columns;
ok ($count > 0, "$count columns in $tablename");
my @columns2 = $tbl->columns();
ok (join(',', @columns2) eq join(',', @columns), "got same list twice");

my @included = qw(sys_id sys_created_on sys_updated_on);
my $icount = @included;
ok ($icount > 0, "$icount columns included");
my @excluded = split /,/, $tbl->except(@included);
my $xcount = @excluded;
ok ($xcount > 0, "$xcount columns excluded");
ok ($xcount < $count, "excluded list is shorter");
my %cnames = map { $_ => 1 } @columns;
my %xnames = map { $_ => 1 } @excluded;
ok (defined $cnames{"description"}, "description is a column");
ok (defined $cnames{"sys_created_on"}, "sys_created_on is a column");
ok (defined $xnames{"description"}, "description excluded");
ok (! defined $xnames{"sys_created_on"}, "sys_created_on not excluded");

done_testing();
1;
