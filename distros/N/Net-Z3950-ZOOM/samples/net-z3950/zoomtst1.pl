# See ../README for a description of this program.
# perl -I../../blib/lib -I../../blib/arch zoomtst1.pl <target> <query>

use strict;
use warnings;
use Net::Z3950;

if (@ARGV != 2) {
    print STDERR "Usage: $0 target query\n";
    print STDERR "	eg. $0 z3950.indexdata.dk/gils computer\n";
    exit 1;
}

my($host, $query) = @ARGV;

# Database name defaults to "Default" in Net::Z3950 and must be overridden
$host =~ s/\/(.*)//;
my $db = $1;
my $conn = new Net::Z3950::Connection($host, 0, databaseName => $db)
    or die "can't connect to '$host': $!";

# Default format is GRS-1 in Net::Z3950
$conn->option(preferredRecordSyntax => "usmarc");

# Default format is "B" in Net::Z3950
$conn->option(elementSetName => "F");

my $rs = $conn->search(-prefix => $query)
    or die "can't search for '$query': ", $conn->errmsg();
my $n = $rs->size();
print "Query '$query' found $n records\n";

# Note that the record-index is 1-based here, 0-based in ZOOM-C
for my $i (1..$n) {
    my $rec = $rs->record($i)
	or die "can't fetch record $i: ", $rs->errmsg();
    print "=== Record $i of $n ===\n";

    # Rendering format for MARC records is different
    print $rec->render(), "\n";
}

$rs->delete();
$conn->close();
