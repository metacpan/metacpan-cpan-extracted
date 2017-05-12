# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 14-sorting.t'

use strict;
use warnings;
use Test::More tests => 29;
use MARC::Record;

BEGIN { use_ok('Net::Z3950::ZOOM') };

my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $host = "z3950.indexdata.com/gils";
my $conn = Net::Z3950::ZOOM::connection_new($host, 0);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "connection to '$host'");

my $qstr = '@attr 1=4 map';
my $query = Net::Z3950::ZOOM::query_create();
Net::Z3950::ZOOM::query_prefix($query, $qstr);
my $res = Net::Z3950::ZOOM::query_sortby($query, "1=4 <i");
ok($res == 0, "sort specification accepted");
my $rs = Net::Z3950::ZOOM::connection_search($conn, $query);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "search for '$qstr'");
my $n = Net::Z3950::ZOOM::resultset_size($rs);
ok($n == 5, "found $n records (expected 5)");

Net::Z3950::ZOOM::resultset_option_set($rs, preferredRecordSyntax => "usmarc");
my $previous = "";		# Sorts before all legitimate titles
foreach my $i (1 .. $n) {
    my $rec = Net::Z3950::ZOOM::resultset_record($rs, $i-1);
    ok(defined $rec, "got record $i of $n");
    my $raw = Net::Z3950::ZOOM::record_get($rec, "raw");
    my $marc = new_from_usmarc MARC::Record($raw);
    my $title = $marc->title();
    ok($title ge $previous, "title '$title' ge previous '$previous'");
    $previous = $title;
}

# Now reverse the order of sorting.  We never use resultset_sort(),
# which is identical to sort1() except that it returns nothing.
my $status = Net::Z3950::ZOOM::resultset_sort1($rs, "yaz", "1=4>i");
ok($status < 0, "malformed sort criterion rejected");
$status = Net::Z3950::ZOOM::resultset_sort1($rs, "yaz", "1=4 >i");
ok($status == 0, "sort criterion accepted");

$previous = "z";		# Sorts after all legitimate titles
foreach my $i (1 .. $n) {
    my $rec = Net::Z3950::ZOOM::resultset_record($rs, $i-1);
    ok(defined $rec, "got record $i of $n");
    my $raw = Net::Z3950::ZOOM::record_get($rec, "raw");
    my $marc = new_from_usmarc MARC::Record($raw);
    my $title = $marc->title();
    ok($title le $previous, "title '$title' le previous '$previous'");
    $previous = $title;
}

Net::Z3950::ZOOM::resultset_destroy($rs);
ok(1, "destroyed result-set");
Net::Z3950::ZOOM::connection_destroy($conn);
ok(1, "destroyed connection");
