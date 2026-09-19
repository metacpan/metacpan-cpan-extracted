use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 'lib';
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::Event;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------
{
	my $p = Music::NWC2MusicXML::Parser->new;
	isa_ok $p, 'Music::NWC2MusicXML::Parser';
}

# ---------------------------------------------------------------------------
# parse: empty / undef input
# ---------------------------------------------------------------------------
{
	my $p = Music::NWC2MusicXML::Parser->new;

	throws_ok { $p->parse(undef) }
		qr/empty/i, 'parse(undef) croaks';

	throws_ok { $p->parse('') }
		qr/empty/i, 'parse("") croaks';
}

# ---------------------------------------------------------------------------
# parse: missing header
# ---------------------------------------------------------------------------
{
	my $p = Music::NWC2MusicXML::Parser->new;

	throws_ok { $p->parse("|SongInfo|Title:\"Test\"\n") }
		qr/header/i, 'parse without NWCTXT header croaks';
}

# ---------------------------------------------------------------------------
# parse: minimal valid NWCTXT (header only)
# ---------------------------------------------------------------------------
{
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score;

	lives_ok {
		$score = $p->parse("!NoteWorthyComposer(2.751)\n");
	} 'header-only NWCTXT parses without exception';

	isa_ok $score, 'Music::NWC2MusicXML::Score';
	is $score->nwc_version, '2.751', 'version extracted from header';
	is $score->staff_count, 0, 'no staves in header-only score';
}

# ---------------------------------------------------------------------------
# parse_song_info
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|SongInfo|Title:"To a Pilgrim"|Author:"Trad, Arr Nigel Horne"',
		;

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	is $score->metadata->{Title},  'To a Pilgrim',         'Title parsed';
	is $score->metadata->{Author}, 'Trad, Arr Nigel Horne', 'Author parsed';
}

# ---------------------------------------------------------------------------
# parse_staff
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Violin I"|Group:"Standard"',
		;

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	is $score->staff_count, 1, 'one staff added';
	is $score->staves->[0]->name, 'Violin I', 'staff name parsed';
}

# ---------------------------------------------------------------------------
# parse_clef
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|Clef|Type:Treble',
		;

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	is $score->staves->[0]->initial_clef, 'Treble',
		'initial clef stored on staff';
}

# ---------------------------------------------------------------------------
# parse_key
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|Key|Signature:Bb|Tonic:D',
		;

	my $score  = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	my $key    = $score->staves->[0]->initial_key;
	is $key->{signature}, 'Bb',  'key signature stored';
	is $key->{fifths},    -1,    'fifths value correct for Bb (1 flat accidental)';
}

# ---------------------------------------------------------------------------
# parse_time_signature
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|TimeSig|Signature:4/4',
		;

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	my $ts    = $score->staves->[0]->initial_timesig;
	is $ts->{beats},     4, 'beats=4';
	is $ts->{beat_type}, 4, 'beat-type=4';
}

# ---------------------------------------------------------------------------
# parse_tempo
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|Clef|Type:Treble',      # ensure events start after initial state
		'|Tempo|Tempo:112|Pos:7',
		;

	my $score  = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	my $events = $score->staves->[0]->events;
	my ($tempo) = grep { $_->type eq 'Tempo' } @$events;
	ok defined $tempo, 'Tempo event created';
	is $tempo->data->{bpm}, 112, 'tempo BPM correct';
}

# ---------------------------------------------------------------------------
# Unknown object -> UnsupportedEvent
# ---------------------------------------------------------------------------
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|SomeFutureNWCObject|Key:Value',
		;

	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) }
		'unknown record type does not croak';

	my $events = $score->staves->[0]->events;
	my ($unsup) = grep { $_->type eq 'UnsupportedEvent' } @$events;
	ok defined $unsup, 'UnsupportedEvent created for unknown type';
	is $unsup->nwc_label, 'SomeFutureNWCObject', 'original label preserved';
}

# ---------------------------------------------------------------------------
# Event: rational duration helpers
# ---------------------------------------------------------------------------
{
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 0);
	is_deeply $r, [1, 1], 'quarter note = 1/1';

	my $dotted = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1);
	is_deeply $dotted, [3, 2], 'dotted quarter = 3/2';

	my $eighth = Music::NWC2MusicXML::Event->rational_from_nwc_duration('8th', 0);
	is_deeply $eighth, [1, 2], 'eighth note = 1/2';
}

done_testing;
