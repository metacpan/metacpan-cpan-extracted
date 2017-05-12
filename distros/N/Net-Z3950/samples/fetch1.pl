#!/usr/bin/perl -w

use Net::Z3950;
$conn = new Net::Z3950::Connection('z3950.loc.gov', 7090,
				   databaseName => 'Voyager')
    or die "can't connect: $!";
$conn->option('preferredRecordSyntax', "USMARC");
$rs = $conn->search('@attr 1=7 0253333490')
    or die "can't search: " . $conn->errmsg() . " (" . $conn->addinfo() . ")";
print "found ", $rs->size(), " records:\n";
exit if $rs->size() == 0;
$rec = $rs->record(1)
    or die "can't get record: " . $rs->errmsg() . " (" . $rs->addinfo() . ")";
print $rec->render();
