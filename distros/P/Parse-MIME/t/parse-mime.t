use strict; use warnings;

use Test::More;
use JSON::PP 'decode_json';
use Parse::MIME ':all';

my $fixtures = decode_json do {
	chdir 't' or die "Couldn't chdir to t: $!\n";
	open my $fh, '<', 'fixtures.json' or die "Couldn't open fixtures: $!\n";
	local $/;
	readline $fh;
};

my $tests;
$tests += $_ for
	map +( ref eq 'HASH' ? 0+keys %$_ : 0+@$_ ),
	map +( ref eq 'HASH' ? $_ : map $_->{'testcases'}, @$_ ),
	values %$fixtures;

plan tests => $tests;

while ( my ( $mime, $parsed ) = each %{ $fixtures->{'parse_mime_type'} } ) {
	is_deeply [ parse_mime_type $mime ], $parsed, "parse_mime_type: $mime";
}

while ( my ( $range, $parsed ) = each %{ $fixtures->{'parse_media_range'} } ) {
	is_deeply [ parse_media_range $range ], $parsed, "parse_media_range: $range";
}

for my $group ( @{ $fixtures->{'quality'} } ) {
	my $accept = $group->{'accept'};
	while ( my ( $type, $quality ) = each %{ $group->{'testcases'} } ) {
		is quality( $type, $accept ), $quality, "quality: $type";
	}
}

for my $group ( @{ $fixtures->{'best_match'} } ) {
	my $mime_types_supported = $group->{'supported'};
	for my $case ( @{ $group->{'testcases'} } ) {
		my ( $range, $result, $desc ) = @$case;
		is best_match( $mime_types_supported, $range ), $result, "best_match: $desc";
	}
}
