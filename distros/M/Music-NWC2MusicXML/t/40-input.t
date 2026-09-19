use strict;
use warnings;

use Test::Most;

use lib 'lib';
use_ok('Music::NWC2MusicXML::NWC');
use_ok('Music::NWC2MusicXML::Parser');
use_ok('Music::NWC2MusicXML::MusicXML');
use XML::PP;

my $input_dir = 't/input';

my @nwc_files = sort glob("$input_dir/*.nwc");

unless (@nwc_files) {
	plan skip_all => "No .nwc files found in $input_dir";
}

my $xml_parser = XML::PP->new();
my $nwc_reader = new_ok('Music::NWC2MusicXML::NWC');
my $parser     = new_ok('Music::NWC2MusicXML::Parser');
my $generator  = new_ok('Music::NWC2MusicXML::MusicXML');

for my $nwc_file (@nwc_files) {
	(my $base = $nwc_file) =~ s/\.nwc$//i;
	my $golden_file = "$base.musicxml";

	diag("Testing $nwc_file") if($ENV{TEST_VERBOSE});

	my $xml;
	lives_ok {
		my $nwctxt = $nwc_reader->read($nwc_file);
		my $score  = $parser->parse($nwctxt);
		$xml = $generator->generate($score);
	} "pipeline converts $nwc_file without exception";

	SKIP: {
		skip "pipeline failed for $nwc_file", 2 unless defined $xml && length $xml;

		my $doc;
		lives_ok {
			$doc = $xml_parser->parse(xml_string => $xml);
		} "$nwc_file output is well-formed XML";

		SKIP: {
			skip "No golden file $golden_file", 1 unless -f $golden_file;

			open my $fh, '<', $golden_file
				or do { fail "Cannot open $golden_file: $!"; last };
			my $golden = do { local $/; <$fh> };
			close $fh;

			is $xml, $golden, "$nwc_file output matches golden $golden_file";
		}
	}
}

done_testing();
