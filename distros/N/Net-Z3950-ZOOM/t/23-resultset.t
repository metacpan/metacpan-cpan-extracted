# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 23-resultset.t'

use strict;
use warnings;
use Test::More tests => 27;
BEGIN { use_ok('ZOOM') };

my $host = "localhost:9996";
my $conn;
eval { $conn = new ZOOM::Connection($host, 0) };
ok(!$@, "connection to '$host'");

my $query = '@attr 1=4 mineral';
my $rs;
eval { $rs = $conn->search_pqf($query) };
ok(!$@, "search for '$query'");
ok($rs->size() == 20, "expected 20 records (got " .  $rs->size() . ")");

my $syntax = "canmarc";		# not supported
$rs->option(preferredRecordSyntax => $syntax);
ok(1, "preferred record syntax was set to '$syntax'");
my $val = $rs->option("preferredRecordSyntax");
ok($val eq $syntax, "preferred record syntax is '$val'");
$val = $rs->option("preferredRecordSyntax");
ok($val eq $syntax, "preferred record syntax is still '$val'");

# At this point, we used to try to fetch a record in CANMARC and note
# that it fails, as it should, with BIB-1 diagnostic 238. But now
# we're testing against yaz-ztest instead of Zebra, it just blithely
# returns an XML record instead. So there's no point doing that test.
# 
# my $rec = $rs->record(0);
# my($errcode, $errmsg) = $rec->error();
# ok($errcode == 238, "can't fetch CANMARC ($errmsg)");

$rs->option(preferredRecordSyntax => "usmarc");
my $rec = $rs->record(0);
my $data1 = $rec->render();
$rs->option(elementSetName => "b");
my $data2 = $rec->render();
ok($data2 eq $data1, "record doesn't know about RS options");
# Now re-fetch record from result-set with new option
$rec = $rs->record(0);
$data2 = $rec->render();

# We would like to test that the brief record is shorter than the full
# one, but yaz-ztest returns the same data for both. So the best we
# can do is test that the brief record is not LONGER than the full.

ok(length($data2) <= length($data1), "brief record is not larger than full");

# If you ask yaz-ztest for an XML record with _any_ element-set
# specified, it fails with a surrogate diagnostic [14] System error in
# presenting records. So we need to reset to no element-set.
$rs->option(elementSetName => "");

$rs->option(preferredRecordSyntax => "xml");
$rec = $rs->record(0);
ok(defined $rec, "fetched XML record");
$data1 = $rec->render();
ok($data1 =~ /<controlfield tag="008">/i, "option for XML syntax is honoured");
my $cloned = $rec->clone();
ok(defined $cloned, "cloned record");
$data2 = $cloned->render();
ok($data2 =~ /<controlfield tag="008">/i, "cloned record XML is good");

# Now we test ZOOM_resultset_record_immediate(), which should only
# work for records that have already been placed in the cache, and
# ZOOM_resultset_records() which populates the cache, and
# ZOOM_resultset_cache_reset(), which presumably empties it.
#
$rec = $rs->record_immediate(0);
ok(defined $rec, "prefetched record obtained with _immediate()");
my $data3 = $rec->render();
ok($data3 eq $data2, "_immediate record renders as expected");
$rec = $rs->record_immediate(1);
#{ use Data::Dumper; print "rec=$rec = ", Dumper($rec) }
ok(!defined $rec, "non-prefetched record obtained with _immediate()");
$rs->cache_reset();
$rec = $rs->record_immediate(0);
ok(!defined $rec, "_immediate(0) fails after cache reset");
# Fill both cache slots, but with no record array
my $tmp = $rs->records(0, 2, 0);
ok(!defined $tmp, "resultset_records() returns undef as expected");
$rec = $rs->record_immediate(0);
ok(defined $rec, "_immediate(0) ok after resultset_records()");
# Fetch all records at once using records()
$tmp = $rs->records(0, 2, 1);
ok(@$tmp == 2, "resultset_records() returned two records");
$data3 = $tmp->[0]->render();
ok($data3 eq $data2, "record returned from resultset_records() renders as expected");
$rec = $rs->record_immediate(1);
ok(defined $rec, "_immediate(1) ok after resultset_records()");

$rs->destroy();
ok(1, "destroyed result-set");
$conn->destroy();
ok(1, "destroyed connection");

$data3 = $cloned->render();
ok(1, "rendered cloned record after its result-set was destroyed");
ok($data3 eq $data2, "render of clone as expected");
$cloned->destroy();
ok(1, "destroyed cloned record");
