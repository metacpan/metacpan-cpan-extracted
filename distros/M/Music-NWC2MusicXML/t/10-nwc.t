use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 'lib';
use Music::NWC2MusicXML::NWC;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------
{
	my $nwc = new_ok('Music::NWC2MusicXML::NWC');
	isa_ok $nwc, 'Music::NWC2MusicXML::NWC', 'constructor returns object';
}

# ---------------------------------------------------------------------------
# decode: empty / undef input
# ---------------------------------------------------------------------------
{
	my $nwc = Music::NWC2MusicXML::NWC->new;

	throws_ok { $nwc->decode(undef) }
		qr/truncated/i,
		'decode(undef) croaks with truncated message';

	throws_ok { $nwc->decode('') }
		qr/truncated/i,
		'decode("") croaks with truncated message';

	throws_ok { $nwc->decode('X' x 4) }
		qr/truncated/i,
		'decode(too-short) croaks';
}

# ---------------------------------------------------------------------------
# decode: wrong magic
# ---------------------------------------------------------------------------
{
	my $nwc  = Music::NWC2MusicXML::NWC->new;
	my $fake = 'NOTANWCFILE' . "\x00" x 64;

	throws_ok { $nwc->decode($fake) }
		qr/not a valid nwc|magic not found/i,
		'decode with wrong magic croaks';
}

# ---------------------------------------------------------------------------
# read: non-existent file
# ---------------------------------------------------------------------------
{
	my $nwc = Music::NWC2MusicXML::NWC->new;

	throws_ok { $nwc->read('/tmp/__does_not_exist_nwc2musicxml__.nwc') }
		qr/cannot read file|not found/i,
		'read non-existent file croaks';
}

# ---------------------------------------------------------------------------
# Corpus tests (skipped when test files absent)
# ---------------------------------------------------------------------------
SKIP: {
	my @corpus = grep { -f $_ } (
		't/corpus/Pilgrim.nwc',
		't/corpus/y2k.nwc',
	);

	skip 'Corpus .nwc files not present in t/corpus/', 2
		unless @corpus == 2;

	my $nwc = Music::NWC2MusicXML::NWC->new;

	for my $file (@corpus) {
		my $nwctxt;
		lives_ok { $nwctxt = $nwc->read($file) }
			"read $file without exception";

		like $nwctxt, qr/^!NoteWorthyComposer\(/m,
			"$file decompresses to valid NWCTXT";
	}
}

done_testing;
