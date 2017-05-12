#!/usr/bin/perl -w

# $Id: batch-isbn.pl,v 1.2 2003/11/21 12:05:47 mike Exp $
#
# Fetch records for a batch of books, the ISBNs of which are read from
# a named file.  Hardwired to use the nasty, slow LoC server.

use Net::Z3950;
use IO::File;
use strict;

die "Usage: batch-isbn.pl <ISBN-file>\n"
    unless @ARGV == 1;

my $filename = $ARGV[0];
my $fh = new IO::File("<$filename")
    or die "can't open ISBN file '$filename': $!";
my @isbn = <$fh>;
$fh->close();

my $query = '@attr 1=7 ' . '@or ' x (@isbn-1) . join('', @isbn);
$query =~ tr/\n/ /;
warn $query;

my $conn = new Net::Z3950::Connection('z3950.loc.gov', 7090,
				      databaseName => 'Voyager')
    or die "can't connect to LoC: $!";

$conn->option(preferredRecordSyntax => "USMARC");
my $rs = $conn->search($query)
    or die $conn->errmsg();
my $n = $rs->size();
print "found $n of " . scalar(@isbn) . " records\n";

for (my $i = 1; $i <= $n; $i++) {
    my $rec = $rs->record($i)
	or die $rs->errmsg();
    print $rec->render();
}
