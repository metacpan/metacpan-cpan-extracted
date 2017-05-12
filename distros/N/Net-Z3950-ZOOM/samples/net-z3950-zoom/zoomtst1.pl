# See ../README for a description of this program.
# perl -I../../blib/lib -I../../blib/arch zoomtst1.pl <target> <query>

use strict;
use warnings;
use Net::Z3950::ZOOM;

if (@ARGV != 2) {
    print STDERR "Usage: $0 target query\n";
    print STDERR "	eg. $0 z3950.indexdata.dk/gils computer\n";
    exit 1;
}

my($host, $query) = @ARGV;
my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $conn = Net::Z3950::ZOOM::connection_new($host, 0);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
die("Can't connect to host '$host': ",
    "errcode='$errcode', errmsg='$errmsg', addinfo='$addinfo'")
    if $errcode != 0;

Net::Z3950::ZOOM::connection_option_set($conn,
					preferredRecordSyntax => "usmarc");

my $rs = Net::Z3950::ZOOM::connection_search_pqf($conn, $query);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
die("Can't search for '$query': ",
    "errcode='$errcode', errmsg='$errmsg', addinfo='$addinfo'")
    if $errcode != 0;

my $n = Net::Z3950::ZOOM::resultset_size($rs);
print "Query '$query' found $n records\n";

for my $i (0..$n-1) {
    my $rec = Net::Z3950::ZOOM::resultset_record($rs, $i);
    print "=== Record ", $i+1, " of $n ===\n";
    print Net::Z3950::ZOOM::record_get($rec, "render");
}

Net::Z3950::ZOOM::resultset_destroy($rs);
Net::Z3950::ZOOM::connection_destroy($conn);
