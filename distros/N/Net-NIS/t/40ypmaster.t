#!perl
#
# Tests for magic __YPMASTER functionality
#
use strict;

use Test::More tests => 1;
eval 'use Test::Differences';	# If available, provides better diagnostics

use Net::NIS qw(:all);

tie my %ypmaster, 'Net::NIS', '__YPMASTER';
if ($yperr != YPERR_SUCCESS()) {
    diag "Skipping: $yperr";
    ok 1, "Skipping test";
    exit 0;
}

# Assemble a hash from the output of 'ypwhich -m'
my $ypwhich_m = qx{ ypwhich -m };
if ($?) {
    diag "Skipping: error running 'ypwhich -m'";
    ok 1, "Skipping test";
    exit 0;
}

my %ypwhich_m;
for my $line (split "\n", $ypwhich_m) {
    if ($line =~ m!^(\S+) \s+ (\S+)$!x) {
	$ypwhich_m{$1} = $2;
    }
    else {
	diag "Aborting test: Cannot grok '$line' from output of ypwhich -m";
	ok 1, "Skipping test";
	exit 0;
    }
}

#
# Pay attention: black magic in action here.
#
# On Linux, which correctly implements yp_maplist(), this test works
# just as you expect: it's a simple hash comparison.
#
# On other OSes, yp_maplist() is unavailable.  That means that %ypmaster
# is an empty hash, because there's no way to get its keys().  *BUT*,
# fortunately, Test::More doesn't seem to compare keys() of its inputs.
# It does seem to iterate over the keys, and *that* works well because
# for a given key $k, $ypmaster{$k} works: it invokes yp_master(),
# which is implemented in Solaris and possibly other OSes.
#
is_deeply \%ypmaster, \%ypwhich_m, "ypwhich -m .vs. our internal code";
