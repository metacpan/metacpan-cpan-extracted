# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2-ZOOM.t'

use strict;
use warnings;
use Test::More tests => 23;
BEGIN { use_ok('ZOOM') };

my $msg = ZOOM::diag_str(ZOOM::Error::INVALID_QUERY);
ok($msg eq "Invalid query", "diagnostic string lookup works");

$msg = ZOOM::diag_srw_str(27);
ok($msg eq "Empty term unsupported", "SRW diagnostic string lookup works");

my $host = "no.such.host";
my $conn;
eval { $conn = new ZOOM::Connection($host, 0) };
# For some reason, Red Hat signals this as a TIMEOUT rather than a CONNECT
ok($@ && $@->isa("ZOOM::Exception") &&
   (($@->code() == ZOOM::Error::CONNECT && $@->addinfo() eq $host) ||
    ($@->code() == ZOOM::Error::TIMEOUT && $@->addinfo() eq "")),
   "connection to non-existent host '$host' fails: \$\@=$@");

$host = "z3950.indexdata.com/gils";
eval { $conn = new ZOOM::Connection($host, 0) };
ok(!$@, "connection to '$host'");

$conn->destroy();
ok(1, "destroyed connection");

eval { $conn = create ZOOM::Connection() };
ok(!$@, "unconnected connection object created");
eval { $conn->connect($host, 0) };
ok(!$@, "delayed connection to '$host'");

my $val1 = "foo";
my $val2 = "$val1\0bar";
$conn->option(xyz => $val2);
my $val = $conn->option("xyz");
ok($val eq $val1, "option() treats value as NUL-terminated");
$conn->option_binary(xyz => $val2, length($val2));
$val = $conn->option_binary("xyz");
ok($val eq $val2, "option_setl() treats value as opaque chunk, val='$val'");

my $syntax = "usmarc";
$conn->option(preferredRecordSyntax => $syntax);
$val = $conn->option("preferredRecordSyntax");
ok($val eq $syntax, "preferred record syntax set to '$val'");

my $query = '@attr @and 1=4 minerals';
my $rs;
eval { $rs = $conn->search_pqf($query) };
ok($@ && $@->isa("ZOOM::Exception") &&
   $@->code() == ZOOM::Error::INVALID_QUERY,
   "search for invalid query '$query' fails");

my($xcode, $xmsg, $xinfo, $xset) = $conn->error_x();
ok($xcode == $@->code() && $xmsg eq $@->message() && $xinfo eq $@->addinfo() &&
   $xset eq $@->diagset(), "error_x() consistent with exception");
ok($conn->errcode() == $@->code(),
   "errcode() consistent with exception");
ok($conn->errmsg() eq $@->message(),
   "errmsg() consistent with exception");
ok($conn->addinfo() eq $@->addinfo(),
   "addinfo() consistent with exception");
ok($conn->diagset() eq $@->diagset(),
   "diagset() consistent with exception");

$query = '@attr 1=4 minerals';
eval { $rs = $conn->search_pqf($query) };
ok(!$@, "search for '$query'");

my $n = $rs->size($rs);
ok($n == 1, "found 1 record as expected");

my $rec = $rs->record(0);
my $data = $rec->render();
ok($data =~ /^245 +\$a ISOTOPIC DATES OF ROCKS AND MINERALS$/m,
   "rendered record has expected title");
my $raw = $rec->raw();
ok($raw =~ /^00966n/, "raw record contains expected header");

$rs->destroy();
ok(1, "destroyed result-set");
$conn->destroy();
ok(1, "destroyed connection");
