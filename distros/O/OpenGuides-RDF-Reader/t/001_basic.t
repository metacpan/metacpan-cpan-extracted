# -*- perl -*-

# t/001_basic.t - Basic tests for RDF parsing

use strict;
use Test::More tests => 3;

#01
BEGIN { use_ok( 'OpenGuides::RDF::Reader' ); }

my $rdf_data = do { local (@ARGV, $/) = 't/sandbox.rdf'; <> };

my %page_data = parse_rdf($rdf_data);

#02
is_deeply( \%page_data, {
	username => 'Housekeeping Robot',
	changed => '2005-10-13T21:30:24',
	version => 74,
	source => 'http://london.openguides.org/index.cgi?Sandbox',
	country => 'United Kingdom',
	city => 'London',
	address => '1 High Street',
	postcode => 'WC5A 2YY',
	phone => '020 7456 7890',
	fax => '020 7654 3210',
	website => 'http://www.mysite.com',
	opening_hours_text => '24 by 7',
	latitude => 51.362603,
	longitude => -0.092219,
	summary => 'A page for testing the system.',
	category => [ 'Beer gardens' ],
	locale => [ 'West End' ],
	}, "sandbox - all fields populated");

$rdf_data = do { local (@ARGV, $/) = 't/amt_expresso.rdf'; <> };

%page_data = parse_rdf($rdf_data);

#03
is_deeply( \%page_data, {
	username => 'Kake',
	changed => '2003-12-10T09:32:37',
	version => 4,
	source => 'http://london.openguides.org/index.cgi?AMT_Espresso',
	country => undef,
	city => undef,
	address => undef,
	postcode => undef,
	phone => undef,
	fax => undef,
	website => 'http://www.amtespresso.co.uk/',
	opening_hours_text => 'Various',
	latitude => undef,
	longitude => undef,
	summary => undef,
	category => [ 'Coffee Shops' ],
	}, "AMT Expresso: see RT #15073");
