#!/usr/bin/perl
use strict;
use warnings;

package # hide from PAUSE
	TestParseMIME;

use File::Basename 'fileparse';
use JSON::XS 'decode_json';

sub load_data {
	my ( $filename ) = @_;

	my $testdata = decode_json do {
		my ( undef, $path ) = fileparse __FILE__, qr/\.pm\z/;
		open my $fh, '<', $path . 'fixtures.json'
			or die "Can't read test fixtures: $!\n";
		local $/;
		<$fh>;
	};

	my ( $key ) = fileparse $filename, qr/\.t\z/;
	$key =~ s/\A[0-9]+\-//;
	return $testdata->{ $key };
}

1;
