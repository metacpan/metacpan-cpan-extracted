# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 28-charset.t'

use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('ZOOM') };

my $host = "z3950.loc.gov:7090/voyager";
my $conn;
eval { $conn = new ZOOM::Connection($host) };
ok(!$@, "connection to '$host'");

$conn->option(preferredRecordSyntax => 'usmarc');

my $qstr = '@attr 1=7 3879093520';
my $rs;
eval { $rs = $conn->search_pqf($qstr) };
ok(!$@, "search for '$qstr'");

my $n = $rs->size();
ok($n == 1, "found $n records (expected 1)");

my $rec = $rs->record(0);
ok(defined $rec, "got first record");

my $xml = $rec->get('xml');
ok(defined $xml, "got XML");

ok($xml =~ m(<subfield code="b">aus der .* f\350ur),
   "got MARC pre-accented composed characters");

$xml = $rec->get('xml', 'charset=marc-8,utf-8');
ok(defined $xml, "got XML in Unicode");

ok($xml =~ m(<subfield code="b">aus der .* für),
   "got Unicode post-accented composed characters");

