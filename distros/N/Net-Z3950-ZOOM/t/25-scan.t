# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 25-scan.t'

use strict;
use warnings;
use Test::More tests => 81;

BEGIN { use_ok('ZOOM') };

my $host = "z3950.indexdata.com/gils";
my $conn;
eval { $conn = new ZOOM::Connection($host, 0) };
ok(!$@, "connection to '$host'");

$conn->option(number => 10);
my($ss, $n) = scan($conn, 0, "w", 10);

my @terms = ();

my $previous = "";		# Sorts before all legitimate terms
foreach my $i (1 .. $n) {
    my($term, $occ) = $ss->term($i-1);
    ok(defined $term,
       "got term $i of $n: '$term' ($occ occurences)");
    ok($term ge $previous, "term '$term' ge previous '$previous'");
    $previous = $term;
    push @terms, $term;
    (my $disp, $occ) = $ss->display_term($i-1);
    ok(defined $disp,
       "display term $i of $n: '$disp' ($occ occurences)");
    ok(lc($disp) eq lc($term),
       "display term $i ($disp) equivalent to term ($term)");
}

$ss->destroy();
ok(1, "destroyed scanset");
eval { $ss->destroy() };
ok(defined $@ && $@ =~ /been destroy\(\)ed/,
   "can't re-destroy scanset");

# Now re-scan, but only for words that occur in the title
# This time, use a Query object for the start-term
($ss, $n) = scan($conn, 1, new ZOOM::Query::PQF('@attr 1=4 w'), 6);

$previous = "";		# Sorts before all legitimate terms
foreach my $i (1 .. $n) {
    my($term, $occ) = $ss->term($i-1);
    ok(defined $term,
       "got title term $i of $n: '$term' ($occ occurences)");
    ok($term ge $previous, "title term '$term' ge previous '$previous'");
    $previous = $term;

    # Previously we used to assert that the each title-term was
    # included in the initial term-list that we got by scanning across
    # all indexes.  Of course this will not in general be true,
    # because not all terms are title terms, which means that the $n
    # title terms will include some that are past the end of $n
    # general terms.  So remove that test.
    #ok((grep { $term eq $_ } @terms), "title term ($term) was in term list (@terms)");
}

$ss->destroy();
ok(1, "destroyed second scanset");

# Now re-do the same scan, but limiting the results to four terms at a
# time.  This time, use a CQL query
$conn->option(number => 4);
$conn->option(cqlfile => "samples/cql/pqf.properties");

($ss, $n) = scan($conn, 1, new ZOOM::Query::CQL2RPN('title=w', $conn), 4);
# Get last term and use it as seed for next scan
my($term, $occ) = $ss->term($n-1);
ok($ss->option("position") == 1,
   "seed-term is start of returned list");
ok(defined $term,
   "got last title term '$term' to use as seed");

$ss->destroy();
ok(1, "destroyed third scanset");

$conn->option(cclfile => "samples/ccl/default.bib");
($ss, $n) = scan($conn, 1, new ZOOM::Query::CCL2RPN('ti=w', $conn), 4);
# Get last term and use it as seed for next scan
($term, $occ) = $ss->term($n-1);
ok($ss->option("position") == 1,
   "seed-term is start of returned list");
ok(defined $term,
   "got last title term '$term' to use as seed");

$ss->destroy();
ok(1, "destroyed fourth scanset");

# We want the seed-term to be in "position zero", i.e. just before the start
$conn->option(position => 0);
($ss, $n) = scan($conn, 0, "\@attr 1=4 $term", 2);
ok($ss->option("position") == 0,
   "seed-term before start of returned list");

# Silly test of option setting and getting
$ss->option(position => "fruit");
ok($ss->option("position") eq "fruit",
   "option setting/getting works");

$ss->destroy();
ok(1, "destroyed fifth scanset");

# Some more testing still to do: see comment in "15-scan.t"


sub scan {
    my($conn, $startterm_is_query, $startterm, $nexpected) = @_;

    my $ss;
    eval {
	if ($startterm_is_query) {
	    $ss = $conn->scan($startterm);
	} else {
	    $ss = $conn->scan_pqf($startterm);
	}
    };
    ok(!$@, "scan for '$startterm'");

    my $n = $ss->size();
    ok(defined $n, "got size");
    ok($n == $nexpected, "got $n terms for '$startterm' (expected $nexpected)");
    return ($ss, $n);
}
