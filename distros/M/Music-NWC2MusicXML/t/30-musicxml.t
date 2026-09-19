use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 'lib';
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------
{
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	isa_ok $gen, 'Music::NWC2MusicXML::MusicXML';
}

# ---------------------------------------------------------------------------
# generate: bad argument
# ---------------------------------------------------------------------------
{
	my $gen = Music::NWC2MusicXML::MusicXML->new;
	throws_ok { $gen->generate('not a score') }
		qr/Music::NWC2MusicXML::Score/i,
		'generate with non-Score croaks';
}

# ---------------------------------------------------------------------------
# generate: empty score (no staves)
# ---------------------------------------------------------------------------
{
	my $gen   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	throws_ok { $gen->generate($score) }
		qr/no staves/i,
		'generate with no staves croaks';
}

# ---------------------------------------------------------------------------
# generate: minimal single-staff score
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(
		name => 'Violin I',
	);
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });

	my $score = Music::NWC2MusicXML::Score->new(
		metadata => { Title => 'Test Score', Author => 'Test Author' },
	);
	$score->add_staff($staff);

	my $gen = Music::NWC2MusicXML::MusicXML->new;
	my $xml;
	lives_ok { $xml = $gen->generate($score) } 'generate does not croak';

	ok defined $xml && length $xml, 'generate returns non-empty string';
	like $xml, qr/<?xml/,              'output starts with XML declaration';
	like $xml, qr/score-partwise/,     'output contains score-partwise element';
	like $xml, qr/Test Score/,         'title present in output';
	like $xml, qr/Test Author/,        'author present in output';
	like $xml, qr/Violin I/,           'staff name present in output';
	like $xml, qr/<divisions>/,        'divisions element present';
	like $xml, qr/<key>/,              'key element present';
	like $xml, qr/<time>/,             'time element present';
	like $xml, qr/<clef>/,             'clef element present';
}

# ---------------------------------------------------------------------------
# XML escaping
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'A & B <Test>');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });

	my $score = Music::NWC2MusicXML::Score->new(
		metadata => { Title => 'Title with "quotes" & ampersands' },
	);
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);

	unlike $xml, qr/&(?!amp;|lt;|gt;|quot;|apos;)/,
		'raw ampersands are escaped';
	unlike $xml, qr/<(?!(?:[a-z\/!?]))/i,
		'raw angle brackets are escaped in text content';
}

# ---------------------------------------------------------------------------
# Hidden staff: _visible = 0 -> print-object="no" on <part-name>
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Hidden');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));
	$staff->{_visible} = 0;

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/print-object="no"/, 'hidden staff emits print-object="no" on part-name';
}

# ---------------------------------------------------------------------------
# Ending bar: _ending_bar = 'SectionClose' -> light-heavy final barline
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));
	$staff->{_ending_bar} = 'SectionClose';

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<bar-style>light-heavy<\/bar-style>/,
		'SectionClose ending_bar emits light-heavy barline';
}

# ---------------------------------------------------------------------------
# Asymmetric page margins: Left != Right -> distinct margin values in output
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));

	my $score = Music::NWC2MusicXML::Score->new(
		page_setup => { Left => 2.54, Right => 1.27 },
	);
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	my ($lm) = ($xml =~ /<left-margin>([^<]+)<\/left-margin>/);
	my ($rm) = ($xml =~ /<right-margin>([^<]+)<\/right-margin>/);
	ok defined($lm) && defined($rm), 'left-margin and right-margin elements present';
	isnt $lm, $rm, 'left and right margins differ when PgMargins are asymmetric';
}

# ---------------------------------------------------------------------------
# DynVel velocity mapping: mf=75 -> <sound dynamics="59"/>
# 75 * 100 / 127 = 59.055...; int(59.055 + 0.5) = 59
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->{_dyn_vel} = { mf => 75 };
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Dynamic',
		duration => [0, 1],
		data     => { marking => 'mf', placement => 'BestFit' },
	));
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<sound dynamics="59"\/>/, 'DynVel mf=75 emits sound dynamics="59"';
}

# ---------------------------------------------------------------------------
# Grace notes: is_grace=1 -> <grace/> present, <duration> absent
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 2],
		data     => { nwc_pos => '0', base_dur => '8th', dots => 0,
		              articulations => [], opts => {}, is_grace => 1 },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like   $xml, qr/<grace\/>/, 'grace note emits <grace/>';
	unlike $xml, qr/<duration>/, 'grace note omits <duration>';
}

# ---------------------------------------------------------------------------
# Font records: StaffLyric -> <lyric-font> in <defaults>
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	push @{ $score->{_fonts} }, {
		style    => 'StaffLyric',
		typeface => 'Times New Roman',
		size     => 12,
		bold     => 0,
		italic   => 0,
	};
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<lyric-font/,                        'StaffLyric font emits <lyric-font>';
	like $xml, qr/font-family="Times New Roman"/,      'lyric-font carries typeface name';
}

# ---------------------------------------------------------------------------
# Slur numbering: two sequential slur arcs get number="1" and number="2"
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });

	# First slur arc: two slurred notes followed by one plain note to close it
	for (1 .. 2) {
		$staff->add_event(Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
			              articulations => ['Slur'], opts => {} },
		));
	}
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));

	# Second slur arc
	for (1 .. 2) {
		$staff->add_event(Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
			              articulations => ['Slur'], opts => {} },
		));
	}
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => { nwc_pos => '0', base_dur => '4th', dots => 0,
		              articulations => [], opts => {} },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/slur number="1" type="start"/, 'first slur arc starts at number 1';
	like $xml, qr/slur number="1" type="stop"/,  'first slur arc stops at number 1';
	like $xml, qr/slur number="2" type="start"/, 'second slur arc starts at number 2';
	like $xml, qr/slur number="2" type="stop"/,  'second slur arc stops at number 2';
}

done_testing;
