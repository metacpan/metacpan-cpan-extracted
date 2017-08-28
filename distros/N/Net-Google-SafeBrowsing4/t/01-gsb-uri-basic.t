#!/usr/bin/perl

# ABSTRACT: Basic tests about the Net::Google::SafeBrowsing4::URI class
# Note: More complicated normalization, extraction and hashing tests should be separated.

use strict;
use warnings;

use Test::More 0.92 qw(no_plan);

BEGIN {
	use_ok('Net::Google::SafeBrowsing4::URI');
}

require_ok('Net::Google::SafeBrowsing4::URI');

my $uri = 'https://google.com/';
my $gsb_uri;
$gsb_uri = new_ok('Net::Google::SafeBrowsing4::URI' => [$uri], qw(Net::Google::SafeBrowsing4::URI));
can_ok($gsb_uri, qw{
	as_string
	generate_lookupuris
	hash
});

is(ref($gsb_uri->as_string()), '', "as_string() method returns the URI as a scalar string");

is(Net::Google::SafeBrowsing4::URI->new(), undef, "Constructor needs parameter.");

SKIP: {
	eval {
		use Test::Pod::Coverage;
	};
	if ($@) {
		skip("Test::Pod::Coverage is not installed Pod coverage test skipped.");
	}

	pod_coverage_ok("Net::Google::SafeBrowsing4::URI");
}
