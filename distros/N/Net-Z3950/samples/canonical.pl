#!/usr/bin/perl -w

use Net::Z3950;
$conn = new Net::Z3950::Connection('z3950.loc.gov', 7090,
				   databaseName => 'Voyager');
$conn->option('preferredRecordSyntax', "USMARC");
$rs = $conn->search('@attr 1=7 0253333490');
$rec = $rs->record(1);
print $rec->render();
