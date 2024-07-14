# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 24-sorting.t'

use strict;
use warnings;
use Test::More tests => 7;
use MARC::Record;

BEGIN { use_ok('ZOOM') };

my $host = "localhost:9996";
my $conn;
eval { $conn = new ZOOM::Connection($host, 0) };
ok(!$@, "connection to '$host'");

my $qstr = '@attr 1=4 map';
my $query = new ZOOM::Query::PQF($qstr);
eval { $query->sortby("1=4 <i") };
ok(!$@, "sort specification accepted");
my $rs;
eval { $rs = $conn->search($query) };
ok(!$@, "search for '$qstr'");
my $n = $rs->size();
ok($n == 18, "found $n records (expected 18)");

# Unfortunately, yaz-ztest simply does not do sorting at all: it just vacuously claims success of thee sorting operation.
# https://github.com/indexdata/yaz/blob/5263d57757507c73c7fdb32f388bc2cd98ba857f/ztest/ztest.c#L816-L821
# So all the code below that tests for correct ordering can't run. See

if (0) {
$rs->option(preferredRecordSyntax => "usmarc");
my $previous = "";		# Sorts before all legitimate titles
foreach my $i (1 .. $n) {
    my $rec = $rs->record($i-1);
    ok(defined $rec, "got record $i of $n");
    my $raw = $rec->raw();
    my $marc = new_from_usmarc MARC::Record($raw);
    my $title = $marc->title();
    ok($title ge $previous, "title '$title' ge previous '$previous'");
    $previous = $title;
}

# Now reverse the order of sorting
my $status = $rs->sort("yaz", "1=4>i");
ok($status < 0, "malformed sort criterion rejected");
$status = $rs->sort("yaz", "1=4 >i");
ok($status == 0, "sort criterion accepted");

$previous = "z";		# Sorts after all legitimate titles
foreach my $i (1 .. $n) {
    my $rec = $rs->record($i-1);
    ok(defined $rec, "got record $i of $n");
    my $raw = $rec->raw();
    my $marc = new_from_usmarc MARC::Record($raw);
    my $title = $marc->title();
    ok($title le $previous, "title '$title' le previous '$previous'");
    $previous = $title;
}
} # if (0)

$rs->destroy();
ok(1, "destroyed result-set");
$conn->destroy();
ok(1, "destroyed connection");
