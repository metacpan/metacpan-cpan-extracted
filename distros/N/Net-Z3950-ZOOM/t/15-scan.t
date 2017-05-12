# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 15-scan.t'

use strict;
use warnings;
use Test::More tests => 81;

BEGIN { use_ok('Net::Z3950::ZOOM') };

my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $host = "z3950.indexdata.com/gils";
my $conn = Net::Z3950::ZOOM::connection_new($host, 0);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "connection to '$host'");

Net::Z3950::ZOOM::connection_option_set($conn, number => 10);
my($ss, $n) = scan($conn, 0, "w", 10);

my @terms = ();
my($occ, $len) = (0, 0);

my $previous = "";		# Sorts before all legitimate terms
foreach my $i (1 .. $n) {
    my $term = Net::Z3950::ZOOM::scanset_term($ss, $i-1, $occ, $len);
    ok(defined $term && $len eq length($term),
       "got term $i of $n: '$term' ($occ occurences)");
    ok($term ge $previous, "term '$term' ge previous '$previous'");
    $previous = $term;
    push @terms, $term;
    my $disp = Net::Z3950::ZOOM::scanset_display_term($ss, $i-1, $occ, $len);
    ok(defined $disp && $len eq length($disp),
       "display term $i of $n: '$disp' ($occ occurences)");
    ok(lc($disp) eq lc($term),
       "display term $i ($disp) equivalent to term ($term)");
}

Net::Z3950::ZOOM::scanset_destroy($ss);
ok(1, "destroyed scanset");
ok(1, "(can't re-destroy scanset)"); # Only meaningful in OO API.

# Now re-scan, but only for words that occur in the title
# This time, use a Query object for the start-term
my $q = Net::Z3950::ZOOM::query_create();
Net::Z3950::ZOOM::query_prefix($q, '@attr 1=4 w');
($ss, $n) = scan($conn, 1, $q, 6);

$previous = "";		# Sorts before all legitimate terms
foreach my $i (1 .. $n) {
    my $term = Net::Z3950::ZOOM::scanset_term($ss, $i-1, $occ, $len);
    ok(defined $term && $len eq length($term),
       "got title term $i of $n: '$term' ($occ occurences)");
    ok($term ge $previous, "title term '$term' ge previous '$previous'");
    $previous = $term;
    # See comment in 25-scan.t
    #ok((grep { $term eq $_ } @terms), "title term ($term) was in term list (@terms)");
}

Net::Z3950::ZOOM::scanset_destroy($ss);
ok(1, "destroyed second scanset");

# Now re-do the same scan, but limiting the results to four terms at a
# time.  This time, use a CQL query
Net::Z3950::ZOOM::connection_option_set($conn, number => 4);
Net::Z3950::ZOOM::connection_option_set($conn, cqlfile =>
					"samples/cql/pqf.properties");

$q = Net::Z3950::ZOOM::query_create();
Net::Z3950::ZOOM::query_cql2rpn($q, 'title=w', $conn);
($ss, $n) = scan($conn, 1, $q, 4);
# Get last term and use it as seed for next scan
my $term = Net::Z3950::ZOOM::scanset_term($ss, $n-1, $occ, $len);
ok(Net::Z3950::ZOOM::scanset_option_get($ss, "position") == 1,
   "seed-term is start of returned list");
ok(defined $term && $len eq length($term),
   "got last title term '$term' to use as seed");

Net::Z3950::ZOOM::scanset_destroy($ss);
ok(1, "destroyed third scanset");

# Now using CCL
$q = Net::Z3950::ZOOM::query_create();
my($ccl_errcode, $ccl_errstr, $ccl_errpos) = (0, "", 0);
Net::Z3950::ZOOM::query_ccl2rpn($q, 'ti=w', "ti u=4 s=pw",
				$ccl_errcode, $ccl_errstr, $ccl_errpos);
($ss, $n) = scan($conn, 1, $q, 4);
# Get last term and use it as seed for next scan
$term = Net::Z3950::ZOOM::scanset_term($ss, $n-1, $occ, $len);
ok(Net::Z3950::ZOOM::scanset_option_get($ss, "position") == 1,
   "seed-term is start of returned list");
ok(defined $term && $len eq length($term),
   "got last title term '$term' to use as seed");

Net::Z3950::ZOOM::scanset_destroy($ss);
ok(1, "destroyed fourth scanset");

# We want the seed-term to be in "position zero", i.e. just before the start
Net::Z3950::ZOOM::connection_option_set($conn, position => 0);
($ss, $n) = scan($conn, 0, "\@attr 1=4 $term", 2);
ok(Net::Z3950::ZOOM::scanset_option_get($ss, "position") == 0,
   "seed-term before start of returned list");

# Silly test of option setting and getting
Net::Z3950::ZOOM::scanset_option_set($ss, position => "fruit");
ok(Net::Z3950::ZOOM::scanset_option_get($ss, "position") eq "fruit",
   "option setting/getting works");

Net::Z3950::ZOOM::scanset_destroy($ss);
ok(1, "destroyed fifth scanset");

# There is no obvious use for scanset_option_set(), and little to be
# done with scanset_option_get(); and I can't find a server that
# returns display terms different from its terms.


sub scan {
    my($conn, $startterm_is_query, $startterm, $nexpected) = @_;

    my $ss;
    if ($startterm_is_query) {
	$ss = Net::Z3950::ZOOM::connection_scan1($conn, $startterm);
    } else {
	$ss = Net::Z3950::ZOOM::connection_scan($conn, $startterm);
    }

    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    ok($errcode == 0, "scan for '$startterm'");

    my $n = Net::Z3950::ZOOM::scanset_size($ss);
    ok(defined $n, "got size");
    ok($n == $nexpected, "got $n terms '$startterm' (expected $nexpected)");
    return ($ss, $n);
}
