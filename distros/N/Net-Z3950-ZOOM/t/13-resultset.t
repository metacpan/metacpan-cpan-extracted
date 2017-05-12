# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 13-resultset.t'

use strict;
use warnings;
use Test::More tests => 24;
BEGIN { use_ok('Net::Z3950::ZOOM') };

my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $host = "z3950.indexdata.com/gils";
my $conn = Net::Z3950::ZOOM::connection_new($host, 0);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "connection to '$host'");

my $query = '@attr 1=4 mineral';
my $rs = Net::Z3950::ZOOM::connection_search_pqf($conn, $query);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "search for '$query'");
ok(Net::Z3950::ZOOM::resultset_size($rs) == 2, "found 2 records");

my $syntax = "canmarc";
Net::Z3950::ZOOM::resultset_option_set($rs, preferredRecordSyntax => $syntax);
my $val = Net::Z3950::ZOOM::resultset_option_get($rs, "preferredRecordSyntax");
ok($val eq $syntax, "preferred record syntax set to '$val'");

my $rec = Net::Z3950::ZOOM::resultset_record($rs, 0);
my $diagset = "";
$errcode = Net::Z3950::ZOOM::record_error($rec, $errmsg, $addinfo, $diagset);
ok($errcode == 238, "can't fetch CANMARC ($errmsg)");

Net::Z3950::ZOOM::resultset_option_set($rs, preferredRecordSyntax => "usmarc");
$rec = Net::Z3950::ZOOM::resultset_record($rs, 0);
my $data1 = Net::Z3950::ZOOM::record_get($rec, "render");
Net::Z3950::ZOOM::resultset_option_set($rs, elementSetName => "b");
my $data2 = Net::Z3950::ZOOM::record_get($rec, "render");
ok($data2 eq $data1, "record doesn't know about RS options");
# Now re-fetch record from result-set with new option
$rec = Net::Z3950::ZOOM::resultset_record($rs, 0);
$data2 = Net::Z3950::ZOOM::record_get($rec, "render");
ok(length($data2) < length($data1), "re-fetched record is brief, old was full");

Net::Z3950::ZOOM::resultset_option_set($rs, preferredRecordSyntax => "xml");
$rec = Net::Z3950::ZOOM::resultset_record($rs, 0);
my $cloned = Net::Z3950::ZOOM::record_clone($rec);
ok(defined $cloned, "cloned record");
$data2 = Net::Z3950::ZOOM::record_get($rec, "render");
ok($data2 =~ /<title>/i, "option for XML syntax is honoured");

# Now we test ZOOM_resultset_record_immediate(), which should only
# work for records that have already been placed in the cache, and
# ZOOM_resultset_records() which populates the cache, and
# ZOOM_resultset_cache_reset(), which presumably empties it.
#
$rec = Net::Z3950::ZOOM::resultset_record_immediate($rs, 0);
ok(defined $rec, "prefetched record obtained with _immediate()");
my $data3 = Net::Z3950::ZOOM::record_get($rec, "render");
ok($data3 eq $data2, "_immediate record renders as expected");
$rec = Net::Z3950::ZOOM::resultset_record_immediate($rs, 1);
ok(!defined $rec, "non-prefetched record obtained with _immediate()");
Net::Z3950::ZOOM::resultset_cache_reset($rs);
$rec = Net::Z3950::ZOOM::resultset_record_immediate($rs, 0);
ok(!defined $rec, "_immediate(0) fails after cache reset");
# Fill both cache slots, but with no record array
my $tmp = Net::Z3950::ZOOM::resultset_records($rs, 0, 2, 0);
ok(!defined $tmp, "resultset_records() returns undef as expected");
$rec = Net::Z3950::ZOOM::resultset_record_immediate($rs, 0);
ok(defined $rec, "_immediate(0) ok after resultset_records()");
# Fetch all records at once using records()
$tmp = Net::Z3950::ZOOM::resultset_records($rs, 0, 2, 1);
ok(@$tmp == 2, "resultset_records() returned two records");
$data3 = Net::Z3950::ZOOM::record_get($tmp->[0], "render");
ok($data3 eq $data2, "record returned from resultset_records() renders as expected");
$rec = Net::Z3950::ZOOM::resultset_record_immediate($rs, 1);
ok(defined $rec, "_immediate(1) ok after resultset_records()");

Net::Z3950::ZOOM::resultset_destroy($rs);
ok(1, "destroyed result-set");
Net::Z3950::ZOOM::connection_destroy($conn);
ok(1, "destroyed connection");

$data3 = Net::Z3950::ZOOM::record_get($cloned, "render");
ok(1, "rendered cloned record after its result-set was destroyed");
ok($data3 eq $data2, "render of clone as expected");
Net::Z3950::ZOOM::record_destroy($cloned);
ok(1, "destroyed cloned record");
