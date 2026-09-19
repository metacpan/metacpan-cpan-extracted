use strict;
use warnings;

use Test::Most;

use lib 'lib';
use_ok('Music::NWC2MusicXML::Parser');
use_ok('Music::NWC2MusicXML::MusicXML');
use_ok('Music::NWC2MusicXML::Score');
use_ok('Music::NWC2MusicXML::Staff');
use_ok('Music::NWC2MusicXML::Event');

# ---------------------------------------------------------------------------
# Helper: build a minimal NWCTXT with a single staff, initial clef/key/time,
# then any extra lines.  Returns the parsed score.
# ---------------------------------------------------------------------------
sub parse_nwctxt {
	my (@extra_lines) = @_;
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|Clef|Type:Treble',
		'|Key|Signature:C',
		'|TimeSig|Signature:4/4',
		# A Bar forces subsequent Clef/Key/TimeSig to be mid-staff events
		'|Note|Dur:4th|Pos:0',
		'|Bar|',
		@extra_lines,
		;
	return Music::NWC2MusicXML::Parser->new->parse($nwctxt);
}

# ---------------------------------------------------------------------------
# Dynamic event parsing
# ---------------------------------------------------------------------------
{
	my $score = parse_nwctxt(
		'|Dynamic|Style:mf|Placement:Below',
	);
	my @evs = grep { $_->type eq 'Dynamic' } @{ $score->staves->[0]->events };
	is scalar @evs, 1, 'one Dynamic event parsed';
	is $evs[0]->data->{marking},   'mf',    'Dynamic marking is mf';
	is $evs[0]->data->{placement}, 'Below', 'Dynamic placement stored';
}

# Dynamic with positional style (no Style: key)
{
	my $score = parse_nwctxt('|Dynamic|ff');
	my @evs = grep { $_->type eq 'Dynamic' } @{ $score->staves->[0]->events };
	is scalar @evs, 1, 'positional Dynamic parsed';
}

# ---------------------------------------------------------------------------
# DynVariance (hairpin) event parsing
# ---------------------------------------------------------------------------
{
	my $score = parse_nwctxt(
		'|DynVariance|Style:Crescendo|Placement:Below',
	);
	my @evs = grep { $_->type eq 'DynVariance' } @{ $score->staves->[0]->events };
	is scalar @evs, 1, 'one DynVariance event parsed';
	is $evs[0]->data->{style},     'Crescendo', 'DynVariance style correct';
	is $evs[0]->data->{placement}, 'Below',     'DynVariance placement stored';
}

{
	my $score = parse_nwctxt('|DynVariance|Style:crescOff');
	my @evs = grep { $_->type eq 'DynVariance' } @{ $score->staves->[0]->events };
	is $evs[0]->data->{style}, 'crescOff', 'crescOff style parsed';
}

{
	my $score = parse_nwctxt('|DynVariance|Style:Diminuendo');
	my @evs = grep { $_->type eq 'DynVariance' } @{ $score->staves->[0]->events };
	is $evs[0]->data->{style}, 'Diminuendo', 'Diminuendo style parsed';
}

# ---------------------------------------------------------------------------
# Tempo event parsing and base field
# ---------------------------------------------------------------------------
{
	my $score = parse_nwctxt('|Tempo|Tempo:120|Base:Quarter');
	my @evs = grep { $_->type eq 'Tempo' } @{ $score->staves->[0]->events };
	is scalar @evs, 1, 'one Tempo event parsed';
	is $evs[0]->data->{bpm},  120,       'Tempo BPM correct';
	is $evs[0]->data->{base}, 'Quarter', 'Tempo base correct';
}

# Default base is Quarter when not supplied
{
	my $score = parse_nwctxt('|Tempo|Tempo:80');
	my @evs = grep { $_->type eq 'Tempo' } @{ $score->staves->[0]->events };
	is $evs[0]->data->{base}, 'Quarter', 'Tempo base defaults to Quarter';
}

# Dotted beat unit
{
	my $score = parse_nwctxt('|Tempo|Tempo:60|Base:Dotted Half');
	my @evs = grep { $_->type eq 'Tempo' } @{ $score->staves->[0]->events };
	is $evs[0]->data->{base}, 'Dotted Half', 'Dotted Half base parsed';
}

# ---------------------------------------------------------------------------
# Tempo before TimeSig in staff header -- has_notes fix regression
# ---------------------------------------------------------------------------
# If Tempo is counted as a "note" (old event_count bug), the subsequent
# TimeSig would be treated as a mid-staff event instead of the initial value.
{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|AddStaff|Name:"Staff"',
		'|Clef|Type:Treble',
		'|Key|Signature:C',
		'|Tempo|Tempo:112',      # Tempo before TimeSig
		'|TimeSig|Signature:3/4',
		;
	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	my $ts = $score->staves->[0]->initial_timesig;
	ok defined $ts, 'initial_timesig set when Tempo precedes TimeSig';
	is $ts->{beats},     3, 'beats=3 (Tempo before TimeSig did not displace it)';
	is $ts->{beat_type}, 4, 'beat_type=4';
}

# ---------------------------------------------------------------------------
# MusicXML output: Dynamic rendered as <dynamics>
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Dynamic',
		data => { marking => 'pp', placement => 'Below' },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<dynamics>/,  'dynamics element present in output';
	like $xml, qr/<pp\/>/,      'pp dynamic marking present';
}

# ---------------------------------------------------------------------------
# MusicXML output: DynVariance rendered as <wedge>
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'DynVariance',
		data => { style => 'Crescendo', placement => 'Below' },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/wedge type="crescendo"/,  'crescendo wedge in output';
}

# ---------------------------------------------------------------------------
# MusicXML output: Tempo rendered as <metronome> + <sound>
# ---------------------------------------------------------------------------
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Tempo',
		data => { bpm => 132, base => 'Quarter' },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<metronome/,            'metronome element present';
	like $xml, qr/<per-minute>132</,      'BPM in output';
	like $xml, qr/sound tempo="132"/,     'sound tempo tag present';
	like $xml, qr/<beat-unit>quarter</,   'beat unit is quarter';
}

# Dotted half tempo: sound bpm = 132 * 3 = 396 quarter-note BPM
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'Tempo',
		data => { bpm => 60, base => 'Dotted Half' },
	));

	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/sound tempo="180"/, 'dotted-half 60 BPM = 180 quarter-note BPM in sound tag';
	like $xml, qr/<beat-unit>half</,  'beat-unit is half';
	like $xml, qr/<beat-unit-dot\/>/,  'beat-unit-dot present for dotted value';
}

# ---------------------------------------------------------------------------
# Articulation emission
# ---------------------------------------------------------------------------

# Helper: build a score with a single note carrying given articulations
sub note_with_artic {
	my (@artic) = @_;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type     => 'Note',
		duration => [1, 1],
		data     => {
			nwc_pos       => '0',
			base_dur      => '4th',
			articulations => \@artic,
		},
	));
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);
	return Music::NWC2MusicXML::MusicXML->new->generate($score);
}

# Tenuto -> <articulations><tenuto/>
{
	my $xml = note_with_artic('Tenuto');
	like $xml, qr/<articulations>/,  'articulations wrapper present for Tenuto';
	like $xml, qr/<tenuto\/>/,       'tenuto element emitted';
}

# Staccato -> <articulations><staccato/>
{
	my $xml = note_with_artic('Staccato');
	like $xml, qr/<staccato\/>/,     'staccato element emitted';
}

# Accent -> <articulations><accent/>
{
	my $xml = note_with_artic('Accent');
	like $xml, qr/<accent\/>/,       'accent element emitted';
}

# Slur token alone: no <articulations> wrapper (Slur is handled by annotate_events)
{
	my $xml = note_with_artic('Slur');
	unlike $xml, qr/<articulations>/, 'Slur-only: no articulations wrapper emitted';
}

# Combined Tenuto + Staccato in one <articulations> block
{
	my $xml = note_with_artic('Tenuto', 'Staccato');
	like $xml, qr/<articulations>/,  'combined articulations wrapper present';
	like $xml, qr/<tenuto\/>/,       'tenuto in combined articulations';
	like $xml, qr/<staccato\/>/,     'staccato in combined articulations';
}

# Trill -> <ornaments><trill-mark/>
{
	my $xml = note_with_artic('Trill');
	like $xml, qr/<ornaments>/,      'ornaments wrapper present for Trill';
	like $xml, qr/<trill-mark\/>/,   'trill-mark element emitted';
}

# Fermata -> <fermata/> directly in <notations> (not wrapped)
{
	my $xml = note_with_artic('Fermata');
	like $xml, qr/<fermata\/>/,      'fermata element emitted';
	unlike $xml, qr/<articulations>/, 'fermata does not produce articulations wrapper';
}

# ---------------------------------------------------------------------------
# Hairpin (wedge) emission from Opts:Crescendo / Opts:Diminuendo on notes
# ---------------------------------------------------------------------------

# Helper: build a score with a sequence of notes, each carrying opts
sub score_with_opts_notes {
	my (@note_opts_list) = @_;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	for my $opts (@note_opts_list) {
		$staff->add_event(Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 4],
			data     => {
				nwc_pos  => '0',
				base_dur => '4th',
				opts     => $opts,
			},
		));
	}
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);
	return Music::NWC2MusicXML::MusicXML->new->generate($score);
}

# Two notes under crescendo -> one start + one stop
{
	my $xml = score_with_opts_notes(
		{ Crescendo => 1 },
		{ Crescendo => 1 },
	);
	my @starts = ($xml =~ /wedge type="crescendo"/g);
	my @stops  = ($xml =~ /wedge type="stop"/g);
	is scalar @starts, 1, 'one crescendo wedge start emitted';
	is scalar @stops,  1, 'one crescendo wedge stop emitted';
}

# Two notes under diminuendo -> one start + one stop
{
	my $xml = score_with_opts_notes(
		{ Diminuendo => 1 },
		{ Diminuendo => 1 },
	);
	my @starts = ($xml =~ /wedge type="diminuendo"/g);
	is scalar @starts, 1, 'one diminuendo wedge start emitted';
}

# Crescendo followed by diminuendo -> stop crescendo, start diminuendo
{
	my $xml = score_with_opts_notes(
		{ Crescendo  => 1 },
		{ Diminuendo => 1 },
	);
	like $xml, qr/wedge type="crescendo"/,  'crescendo start present';
	like $xml, qr/wedge type="diminuendo"/, 'diminuendo start present';
	my @stops = ($xml =~ /wedge type="stop"/g);
	is scalar @stops, 2, 'two stops emitted (one per hairpin)';
}

# No Opts: no wedge elements
{
	my $xml = score_with_opts_notes({}, {});
	unlike $xml, qr/wedge/, 'no wedge when no Opts hairpin';
}

# ---------------------------------------------------------------------------
# TempoVariance emission (accel., rit., rall., a tempo)
# ---------------------------------------------------------------------------

sub score_with_tempo_variance {
	my ($style, $placement) = @_;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(Music::NWC2MusicXML::Event->new(
		type => 'TempoVariance',
		data => { style => $style, placement => $placement // 'above' },
	));
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff($staff);
	return Music::NWC2MusicXML::MusicXML->new->generate($score);
}

{
	my $xml = score_with_tempo_variance('Accelerando');
	like $xml, qr/<words[^>]*>accel\.<\/words>/,  'Accelerando emitted as accel.';
	like $xml, qr/font-style="italic"/,           'words element has italic style';
}

{
	my $xml = score_with_tempo_variance('Ritardando');
	like $xml, qr/<words[^>]*>rit\.<\/words>/,    'Ritardando emitted as rit.';
}

{
	my $xml = score_with_tempo_variance('Rallentando');
	like $xml, qr/<words[^>]*>rall\.<\/words>/,   'Rallentando emitted as rall.';
}

{
	my $xml = score_with_tempo_variance('RitardandoToTempo');
	like $xml, qr/<words[^>]*>a tempo<\/words>/,  'RitardandoToTempo emitted as a tempo';
}

# Placement 'above' maps to placement="above" on the direction element
{
	my $xml = score_with_tempo_variance('Accelerando', 'above');
	like $xml, qr/direction placement="above"/,   'above placement used';
}

# ---------------------------------------------------------------------------
# Copyright extraction (Copyright1 / Copyright2) and <credit> emission
# ---------------------------------------------------------------------------

{
	my $nwctxt = join "\n",
		'!NoteWorthyComposer(2.751)',
		'|SongInfo|Title:"Test"|Copyright1:"Copyright (c) 2025 Test"|Copyright2:"All Rights Reserved"',
		'|AddStaff|Name:"Staff"',
		'|Clef|Type:Treble',
		'|Key|Signature:C',
		'|TimeSig|Signature:4/4',
		;
	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	is $score->metadata->{Copyright1}, 'Copyright (c) 2025 Test', 'Copyright1 extracted from SongInfo';
	is $score->metadata->{Copyright2}, 'All Rights Reserved',      'Copyright2 extracted from SongInfo';

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);

	# Title credit on page 1
	like $xml, qr/<credit page="1">.*?<credit-type>title<\/credit-type>/s,
		'title credit page="1" present';
	like $xml, qr/credit-type>title<\/credit-type>.*?Test.*?<\/credit-words>/s,
		'title text in title credit';

	# Copyright credit has NO page attribute -> appears on all pages
	like $xml, qr/<credit>\s*<credit-type>rights<\/credit-type>/,
		'rights credit has no page attribute (all pages)';
	like $xml, qr/<credit-type>rights<\/credit-type>/,  'credit-type is rights';

	# Both copyright lines appear as separate <credit-words>
	like $xml, qr/Copyright \(c\) 2025 Test.*?<\/credit-words>/s,
		'Copyright1 text in credit-words';
	like $xml, qr/All Rights Reserved.*?<\/credit-words>/s,
		'Copyright2 text in credit-words';

	# Both combined into one <rights> element (two separate elements cause
	# renderers to discard all but the last)
	like $xml, qr/<rights>Copyright \(c\) 2025 Test\nAll Rights Reserved<\/rights>/,
		'Copyright1 and Copyright2 combined in identification rights';
}

# Non-ASCII in copyright is escaped as numeric entity
{
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Test');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ signature => 'C', tonic => 'C', fifths => 0 });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	my $score = Music::NWC2MusicXML::Score->new;
	$score->set_metadata_field('Copyright1', "Copyright \x{a9} 2025");
	$score->add_staff($staff);
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/Copyright &#169; 2025/, 'non-ASCII copyright symbol escaped as &#169;';
	unlike $xml, qr/[^\x00-\x7F]/, 'output is pure ASCII';
}

done_testing();
