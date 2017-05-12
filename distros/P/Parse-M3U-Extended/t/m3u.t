#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use JSON;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my @glob;

BEGIN {
	@glob = glob('t/data/*.m3u t/data/*.m3ue');
	plan tests => 1 + @glob;
	use_ok 'Parse::M3U::Extended', 'm3u_parser';
}

sub __slurp {
	my $fname = shift;

	open my $fh, '<', $fname or die("Could not open '$fname': $!\n");
	my $file = do { local $/; <$fh> };
	close $fh;

	return $file;
}

for my $test_m3u (@glob) {
	my $ref_file = $test_m3u;
	$ref_file =~ s/\.m3ue?$/.json/;

	my $m3u = __slurp($test_m3u);
	my $ref = __slurp($ref_file);

	is_deeply
		[ m3u_parser($m3u) ],
		decode_json $ref,
		"expected items found for $test_m3u";
}

