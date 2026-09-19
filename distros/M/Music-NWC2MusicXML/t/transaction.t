#!/usr/bin/env perl
# transaction.t -- Transaction-flow tests: multi-stage lifecycle, mid-flight
# failure isolation, rollback assertions, and idempotency checks.
# Each subtest is a distinct lifecycle phase, not an individual function test.
use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock_scoped);
use Scalar::Util qw(blessed);
use File::Temp qw(tempdir);
use File::Spec ();
use File::Basename qw(basename);
use Compress::Zlib;
use Readonly;

use Music::NWC2MusicXML;
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::Diagnostics;

# ---------------------------------------------------------------------------
# Constants -- no magic strings/numbers in tests
# ---------------------------------------------------------------------------

Readonly::Scalar my $NWC_MAGIC   => '[NWZ]';
Readonly::Scalar my $NWC_VERSION => '2.751';
Readonly::Scalar my $OUTPUT_EXT  => '.musicxml';
Readonly::Scalar my $PILGRIM_NWC => 't/input/Pilgrim.nwc';

# Base NWCTXT header/footer shared by all synthetic scores
Readonly::Scalar my $HDR => "!NoteWorthyComposer($NWC_VERSION)\n|SongInfo|Title:Tx\n";
Readonly::Scalar my $FTR => "!NoteWorthyComposer-End\n";

# A self-contained single-staff, one-bar, 4/4 Treble score block
Readonly::Scalar my $TREBLE_ONE_BAR =>
	"|AddStaff|Name:\"Piano\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n";

# Three-staff chamber score block
Readonly::Scalar my $THREE_STAVES =>
	"|AddStaff|Name:\"Violin\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n"
	. "|AddStaff|Name:\"Viola\"\n"
	. "|Clef|Type:Alto\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n"
	. "|AddStaff|Name:\"Cello\"\n"
	. "|Clef|Type:Bass\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n";

# Accidental transaction: bar 1 has C#5,C5,Cn5,C5; bar 2 has C5,C5,C5,C5
# Treble pos=1 -> C5 (ref B4 at index 34; pos 1 -> index 35 -> C5)
Readonly::Scalar my $ACCIDENTAL_SCORE =>
	"|AddStaff|Name:\"Acc\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:4th|Pos:#1\n"   # C#5 -- explicit sharp; bar_acc[C5]=1
	. "|Note|Dur:4th|Pos:1\n"    # C5  -- carry: alter=1
	. "|Note|Dur:4th|Pos:n1\n"   # Cn5 -- explicit natural; bar_acc[C5]=0
	. "|Note|Dur:4th|Pos:1\n"    # C5  -- carry: alter=0
	. "|Bar|\n"
	. "|Note|Dur:4th|Pos:1\n"    # C5 bar 2 -- bar_acc reset; alter=0 from key
	. "|Note|Dur:4th|Pos:1\n"    # C5 -- still 0
	. "|Note|Dur:4th|Pos:1\n"    # C5
	. "|Note|Dur:4th|Pos:1\n"    # C5
	. "|Bar|\n";

# Duration chain: 2 quarters + 4 eighths -> LCM(1,2)=2 -> divisions=2
Readonly::Scalar my $MIXED_DUR_SCORE =>
	"|AddStaff|Name:\"Dur\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:4th|Pos:0\n"
	. "|Note|Dur:4th|Pos:0\n"
	. "|Note|Dur:8th|Pos:0\n"
	. "|Note|Dur:8th|Pos:0\n"
	. "|Note|Dur:8th|Pos:0\n"
	. "|Note|Dur:8th|Pos:0\n"
	. "|Bar|\n";

# Mid-staff key-change score: bar 1 Concert (fifths=0), bar 2 D major (fifths=2)
Readonly::Scalar my $KEY_CHANGE_SCORE =>
	"|AddStaff|Name:\"Key\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n"
	. "|Key|Signature:F#,C#\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n";

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _nwctxt       { return $HDR . $_[0] . $FTR }
sub _compress     { return Compress::Zlib::compress(\$_[0]) }
sub _make_binary  { return $NWC_MAGIC . _compress(_nwctxt($_[0])) }

# Write a valid NWC binary to a temp file; caller must retain the returned
# File::Temp object or the file is deleted immediately.
sub _write_valid_nwc {
	my ($staves) = @_;
	my $fh = File::Temp->new(SUFFIX => '.nwc', UNLINK => 1);
	binmode $fh;
	print $fh _make_binary($staves);
	$fh->close;
	return $fh;
}

# Write a garbage binary that will cause NWC::decode to croak.
sub _write_corrupt_nwc {
	my $fh = File::Temp->new(SUFFIX => '.nwc', UNLINK => 1);
	binmode $fh;
	print $fh "GARBAGE_NOT_NWZ\x00" x 30;
	$fh->close;
	return $fh;
}

sub _quiet_converter { return Music::NWC2MusicXML->new(log_level => 'quiet') }
sub _parse  { return Music::NWC2MusicXML::Parser->new->parse(_nwctxt($_[0])) }
sub _gen    { return Music::NWC2MusicXML::MusicXML->new->generate($_[0]) }

# ============================================================================
# Transaction 1: Full 3-stage pipeline lifecycle
# ============================================================================
#
# Walk a NWC binary file through every stage of the pipeline and assert state
# at each boundary.  This is the canonical happy-path transaction.

subtest 'Transaction 1: full 3-stage pipeline -- NWC binary file -> XML file' => sub {
	my $outdir = tempdir(CLEANUP => 1);
	my $src    = _write_valid_nwc($TREBLE_ONE_BAR);
	my $srcpath = $src->filename;

	my $xmlname = basename($srcpath);
	$xmlname =~ s/\.nwc$/$OUTPUT_EXT/i;
	my $expected_out = File::Spec->catfile($outdir, $xmlname);

	# Pre-condition: no output exists yet
	ok !-f $expected_out, 'Pre-condition: output file absent before conversion';

	# ---- Stage 1: NWC binary -> NWCTXT (NWC.pm) ----------------------------
	my $nwctxt = Music::NWC2MusicXML::NWC->read($srcpath);
	ok defined $nwctxt,                       'Stage 1 D: NWCTXT is defined';
	ok length($nwctxt) > 0,                   'Stage 1 D: NWCTXT is non-empty';
	like $nwctxt, qr/^!NoteWorthyComposer\(/, 'Stage 1 U: NWCTXT has header marker';
	like $nwctxt, qr/\|AddStaff\|/,           'Stage 1 U: NWCTXT contains AddStaff';

	# ---- Stage 2: NWCTXT -> Score (Parser.pm) -------------------------------
	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	ok blessed($score) && $score->isa('Music::NWC2MusicXML::Score'),
		'Stage 2 D: Score object created';
	is $score->staff_count, 1, 'Stage 2 U: one staff parsed';
	ok $score->staves->[0]->has_notes,
		'Stage 2 U: staff has at least one note';

	# ---- Stage 3: Score -> XML string (MusicXML.pm) -------------------------
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	ok defined $xml,                           'Stage 3 D: XML string defined';
	like $xml, qr/^<\?xml /,                  'Stage 3 U: begins with XML declaration';
	like $xml, qr/<score-partwise/,            'Stage 3 U: contains score-partwise';
	like $xml, qr/<part id="P1"/,             'Stage 3 U: part P1 present';
	like $xml, qr/<\/score-partwise>\s*$/,    'Stage 3 U: root element closed at end';

	# ---- Stage 4: facade convert -> output file (NWC2MusicXML.pm) ----------
	my $c   = _quiet_converter();
	my $out = $c->convert(input => $srcpath, output => $expected_out, overwrite => 1);
	is $out, $expected_out, 'Stage 4 U: convert() returns output path';
	ok -f $expected_out,    'Stage 4 K: output file written to disk';
	ok -s $expected_out > 0,'Stage 4 K: output file is non-empty';

	# Verify XML written to disk is the same as the generated string
	open my $fh, '<:encoding(UTF-8)', $expected_out or die $!;
	local $/;
	my $disk_xml = <$fh>;
	close $fh;
	is $disk_xml, $xml, 'Stage 4 K: disk XML matches in-memory XML (no truncation)';
};

# ============================================================================
# Transaction 2: Stage-1 decode failure -- no orphaned output, clean rollback
# ============================================================================
#
# A corrupt binary that cannot be decompressed must not produce an output file
# and must be counted as a failure, leaving subsequent operations unaffected.

subtest 'Transaction 2: stage-1 decode failure -- clean rollback, no orphan' => sub {
	my $outdir  = tempdir(CLEANUP => 1);
	my $corrupt = _write_corrupt_nwc();
	my $xmlout  = File::Spec->catfile($outdir, 'corrupt' . $OUTPUT_EXT);
	my $c       = _quiet_converter();

	# The convert() call must not croak (the facade catches internal failures)
	my $result = eval { $c->convert(input => $corrupt->filename, output => $xmlout, overwrite => 1) };
	my $err    = $@;

	is $result, undef,       'Tx2: convert() returns undef on decode failure';
	ok !$err,                'Tx2: no uncaught exception propagates to caller';
	ok !-f $xmlout,          'Tx2: no orphaned output file after decode failure';

	# Post-condition: the converter remains functional for subsequent valid input
	my $good   = _write_valid_nwc($TREBLE_ONE_BAR);
	my $goodout = File::Spec->catfile($outdir, 'good' . $OUTPUT_EXT);
	my $ok = $c->convert(input => $good->filename, output => $goodout, overwrite => 1);
	is $ok, $goodout, 'Tx2 post: converter is still functional after decode failure';
	ok -f $goodout,   'Tx2 post: good file converts successfully after prior failure';
};

# ============================================================================
# Transaction 3: Stage-3 generate failure -- mocked to die mid-pipeline
# ============================================================================
#
# If the generate stage dies unexpectedly, the facade must catch it, leave no
# output file, and return undef.

subtest 'Transaction 3: stage-3 generate failure (mocked) -- no orphaned output' => sub {
	my $outdir  = tempdir(CLEANUP => 1);
	my $src     = _write_valid_nwc($TREBLE_ONE_BAR);
	my $xmlout  = File::Spec->catfile($outdir, 'failed' . $OUTPUT_EXT);

	my $guard = mock_scoped(
		'Music::NWC2MusicXML::MusicXML', 'generate',
		sub { Carp::croak('Simulated generate failure') },
	);

	my $c = _quiet_converter();
	my $result = eval { $c->convert(input => $src->filename, output => $xmlout, overwrite => 1) };
	my $err    = $@;

	is $result, undef, 'Tx3: convert() returns undef when generate dies';
	ok !$err,          'Tx3: exception is caught; caller sees no croak';
	ok !-f $xmlout,    'Tx3: no output file written when generate fails';

	undef $guard;

	# Post-condition: generate works normally after mock is released
	my $good_xml = eval { _gen(_parse($TREBLE_ONE_BAR)) };
	ok !$@,                      'Tx3 post: generate works normally after mock release';
	like $good_xml, qr/<part /, 'Tx3 post: generated XML contains part element';
};

# ============================================================================
# Transaction 4: batch_convert with partial failure -- isolation between files
# ============================================================================
#
# A 3-file batch (good / corrupt / good) must process all 3, succeed on the
# good ones, fail on the corrupt one, and not let the failure abort the batch.

subtest 'Transaction 4: batch_convert good/corrupt/good -- failure isolation' => sub {
	my $outdir = tempdir(CLEANUP => 1);

	my $file_a = _write_valid_nwc($TREBLE_ONE_BAR);
	my $file_b = _write_corrupt_nwc();
	my $file_c = _write_valid_nwc($TREBLE_ONE_BAR);

	my $stem_a = basename($file_a->filename); $stem_a =~ s/\.nwc$//i;
	my $stem_c = basename($file_c->filename); $stem_c =~ s/\.nwc$//i;
	my $stem_b = basename($file_b->filename); $stem_b =~ s/\.nwc$//i;

	my $c = _quiet_converter();
	my $r = $c->batch_convert(
		inputs     => [$file_a->filename, $file_b->filename, $file_c->filename],
		output_dir => $outdir,
		overwrite  => 1,
	);

	# Summary counts
	is $r->{processed},  3, 'Tx4: 3 files processed';
	is $r->{successful}, 2, 'Tx4: 2 successful conversions';
	is $r->{failed},     1, 'Tx4: 1 failed conversion';

	# Per-file output: good files must have output; corrupt must not
	ok -f File::Spec->catfile($outdir, $stem_a . $OUTPUT_EXT),
		'Tx4: file A (good) produced XML output';
	ok -f File::Spec->catfile($outdir, $stem_c . $OUTPUT_EXT),
		'Tx4: file C (good) produced XML output';
	ok !-f File::Spec->catfile($outdir, $stem_b . $OUTPUT_EXT),
		'Tx4: file B (corrupt) produced no output';

	# results arrayref: all 3 entries present
	is scalar @{ $r->{results} }, 3, 'Tx4: results arrayref has 3 entries';
	ok $r->{results}[0]{ok},  'Tx4: result[0] (good) ok flag is true';
	ok !$r->{results}[1]{ok}, 'Tx4: result[1] (corrupt) ok flag is false';
	ok $r->{results}[2]{ok},  'Tx4: result[2] (good) ok flag is true';
};

# ============================================================================
# Transaction 5: batch_convert idempotency -- same inputs, same outputs
# ============================================================================
#
# Running the same conversion twice with overwrite=1 must produce identical
# output files and identical summary counts (no state leaked between runs).

subtest 'Transaction 5: batch_convert idempotency -- two runs produce identical output' => sub {
	my $outdir = tempdir(CLEANUP => 1);
	my $src    = _write_valid_nwc($TREBLE_ONE_BAR);
	my $stem   = basename($src->filename); $stem =~ s/\.nwc$//i;
	my $xmlout = File::Spec->catfile($outdir, $stem . $OUTPUT_EXT);

	my $c = _quiet_converter();

	# First run
	my $r1 = $c->batch_convert(
		inputs => [$src->filename], output_dir => $outdir, overwrite => 1);
	is $r1->{successful}, 1, 'Tx5 run1: 1 successful';
	is $r1->{failed},     0, 'Tx5 run1: 0 failed';
	ok -f $xmlout, 'Tx5 run1: output file exists';

	open my $fh1, '<:encoding(UTF-8)', $xmlout or die $!;
	local $/;
	my $xml1 = <$fh1>;
	close $fh1;

	# Second run -- same converter instance, same inputs
	my $r2 = $c->batch_convert(
		inputs => [$src->filename], output_dir => $outdir, overwrite => 1);
	is $r2->{successful}, 1, 'Tx5 run2: still 1 successful';
	is $r2->{failed},     0, 'Tx5 run2: still 0 failed';

	open my $fh2, '<:encoding(UTF-8)', $xmlout or die $!;
	my $xml2 = <$fh2>;
	close $fh2;

	is $xml2, $xml1,
		'Tx5: second run output is byte-for-byte identical to first run (no state leak)';
};

# ============================================================================
# Transaction 6: Parser state isolation between sequential parses
# ============================================================================
#
# Two independent Parser::parse calls must produce fully independent Score
# objects; state from parse A must not bleed into parse B.

subtest 'Transaction 6: parser state isolation -- two sequential parses are independent' => sub {
	my $nwctxt_a = _nwctxt($THREE_STAVES);       # 3 staves, Concert key
	my $nwctxt_b = _nwctxt($TREBLE_ONE_BAR);     # 1 staff, Concert key

	my $parser = Music::NWC2MusicXML::Parser->new;

	my $score_a = $parser->parse($nwctxt_a);
	is $score_a->staff_count, 3, 'Tx6 parse A: 3 staves';

	# Immediately parse a different score with the SAME parser instance
	my $score_b = $parser->parse($nwctxt_b);
	is $score_b->staff_count, 1, 'Tx6 parse B: 1 staff (not contaminated by A)';

	# Verify A is unchanged (no shared mutable reference)
	is $score_a->staff_count, 3, 'Tx6: score A still has 3 staves after parse B';

	# Staff names from B must not bleed into A
	isnt $score_b->staves->[0]->name, $score_a->staves->[0]->name,
		'Tx6: B staff name differs from A staff name (independent objects)';

	# XML generation for both must produce independent output
	my $xml_a = _gen($score_a);
	my $xml_b = _gen($score_b);
	isnt $xml_a, $xml_b, 'Tx6: XML outputs for A and B differ (not the same object)';

	my $parts_a = () = $xml_a =~ /<part /g;
	my $parts_b = () = $xml_b =~ /<part /g;
	is $parts_a, 3, 'Tx6: XML A has 3 parts';
	is $parts_b, 1, 'Tx6: XML B has 1 part';
};

# ============================================================================
# Transaction 7: Multi-staff score assembly -- consistency at every boundary
# ============================================================================
#
# Parse -> validate -> generate: staff counts, names, and XML part counts
# must agree at every phase boundary.

subtest 'Transaction 7: multi-staff score assembly lifecycle -- counts consistent' => sub {
	# Phase 1: parse
	my $score = _parse($THREE_STAVES);
	is $score->staff_count, 3, 'Phase 1 (parse): 3 staves in Score';

	my @staves = @{ $score->staves };
	is $staves[0]->name, 'Violin', 'Phase 1: Staff 0 name = Violin';
	is $staves[1]->name, 'Viola',  'Phase 1: Staff 1 name = Viola';
	is $staves[2]->name, 'Cello',  'Phase 1: Staff 2 name = Cello';

	# Each staff must have at least one note event
	ok $_->has_notes, "Phase 1: ${\$_->name} has notes" for @staves;

	# Phase 2: validate
	my $issues = $score->validate;
	is scalar @$issues, 0, 'Phase 2 (validate): no validation issues';

	# Phase 3: generate XML
	my $xml = _gen($score);
	ok defined $xml, 'Phase 3 (generate): XML is defined';

	# XML must have exactly 3 <part id=...> and 3 <score-part id=...> elements
	my $part_count       = () = $xml =~ /<part id=/g;
	my $score_part_count = () = $xml =~ /<score-part id=/g;
	is $part_count,       3, 'Phase 3: 3 <part id=...> elements in XML';
	is $score_part_count, 3, 'Phase 3: 3 <score-part id=...> elements in XML';

	# Part names must appear in the XML part-list
	like $xml, qr/<part-name>Violin<\/part-name>/, 'Phase 3: Violin in part-list';
	like $xml, qr/<part-name>Viola<\/part-name>/,  'Phase 3: Viola in part-list';
	like $xml, qr/<part-name>Cello<\/part-name>/,  'Phase 3: Cello in part-list';
};

# ============================================================================
# Transaction 8: Accidental carry-through within a bar
# ============================================================================
#
# Once a C# appears in a measure, all subsequent bare C positions in the same
# measure must carry the sharp (alter=1) without an explicit accidental tag.
# A natural sign resets the carry for the rest of the bar.

subtest 'Transaction 8: accidental carry-through transaction within a bar' => sub {
	# Parse and generate the accidental score defined in the constants section.
	# Bar 1: #1(C#), 1(C), n1(Cn), 1(C)   -> alters: 1, 1, 0, 0
	# Bar 2: 1,1,1,1 (all plain C)          -> alters: 0, 0, 0, 0 (bar reset)
	my $score = _parse($ACCIDENTAL_SCORE);
	my $xml   = _gen($score);

	# Extract alter values and accidental tags per measure by splitting the XML
	# at each <measure> boundary so we can count per-bar.
	my @measures = ($xml =~ /<measure[^>]*>(.*?)<\/measure>/gs);

	# We expect at least 2 measures in the output
	ok scalar @measures >= 2, 'Tx8: at least 2 measures generated';

	my $bar1 = $measures[0] // '';
	my $bar2 = $measures[1] // '';

	# Bar 1: exactly 2 <alter> elements (for C# notes 1 and 2)
	my $bar1_alters = () = $bar1 =~ /<alter>/g;
	is $bar1_alters, 2,
		'Tx8 bar1: 2 <alter> elements (C# carry on note 2; natural zeroes notes 3-4)';

	# Bar 1: exactly 2 explicit accidental tags (sharp on note 1, natural on note 3)
	my $bar1_acc = () = $bar1 =~ /<accidental>/g;
	is $bar1_acc, 2,
		'Tx8 bar1: 2 <accidental> elements (sharp and natural)';
	like $bar1, qr/<accidental>sharp<\/accidental>/,   'Tx8 bar1: sharp tag present';
	like $bar1, qr/<accidental>natural<\/accidental>/, 'Tx8 bar1: natural tag present';

	# Bar 2: no <alter> elements -- bar_accidentals reset at the barline
	my $bar2_alters = () = $bar2 =~ /<alter>/g;
	is $bar2_alters, 0,
		'Tx8 bar2: no <alter> elements (carry-through does not cross barline)';

	my $bar2_acc = () = $bar2 =~ /<accidental>/g;
	is $bar2_acc, 0,
		'Tx8 bar2: no explicit <accidental> tags (no prefix on any bar-2 note)';
};

# ============================================================================
# Transaction 9: Duration rational chain -- LCM divisions, tick consistency
# ============================================================================
#
# A score with quarter and eighth notes requires divisions=2.  Every note's
# <duration> tick value must be consistent with that declaration.

subtest 'Transaction 9: duration rational chain -- LCM divisions consistency' => sub {
	my $score = _parse($MIXED_DUR_SCORE);
	my $xml   = _gen($score);

	# Verify divisions=2 is declared (LCM of denominators 1 and 2)
	like $xml, qr/<divisions>2<\/divisions>/, 'Tx9: <divisions>2</divisions> declared';

	# Extract all <duration> values
	my @durations = ($xml =~ /<duration>(\d+)<\/duration>/g);

	# 2 quarters (2 ticks each) + 4 eighths (1 tick each) = 8 notes
	is scalar @durations, 6, 'Tx9: 6 note duration elements in output';

	my @twos = grep { $_ == 2 } @durations;
	my @ones = grep { $_ == 1 } @durations;
	is scalar @twos, 2, 'Tx9: 2 quarter notes -> duration=2 each';
	is scalar @ones, 4, 'Tx9: 4 eighth notes -> duration=1 each';

	# Total ticks = 2*2 + 4*1 = 8 = one 4/4 bar at divisions=2
	my $total = 0; $total += $_ for @durations;
	is $total, 8, 'Tx9: total ticks = 8 (one 4/4 bar at divisions=2)';
};

# ============================================================================
# Transaction 10: Mid-staff key change sequence
# ============================================================================
#
# A key change appearing after the first sounding note must not alter the
# initial <attributes> block and must produce a new <attributes> block
# mid-staff at the point of the change.

subtest 'Transaction 10: mid-staff key change transaction' => sub {
	my $score = _parse($KEY_CHANGE_SCORE);
	my $xml   = _gen($score);

	# At least 2 measures
	my @measures = ($xml =~ /<measure[^>]*>(.*?)<\/measure>/gs);
	ok scalar @measures >= 2, 'Tx10: at least 2 measures in output';

	my $bar1 = $measures[0] // '';
	my $bar2 = $measures[1] // '';

	# Bar 1 initial attributes: Concert key -> fifths=0
	like $bar1, qr/<fifths>0<\/fifths>/,
		'Tx10 bar1: initial attributes have fifths=0 (Concert key)';

	# Bar 2 mid-staff change: D major -> fifths=2
	like $bar2, qr/<fifths>2<\/fifths>/,
		'Tx10 bar2: mid-staff attributes have fifths=2 (D major)';

	# The initial attributes block must NOT carry fifths=2 (no premature key)
	unlike $bar1, qr/<fifths>2<\/fifths>/,
		'Tx10 bar1: initial attributes do not contain fifths=2 (no premature key change)';
};

# ============================================================================
# Transaction 11: Part name resolution priority chain
# ============================================================================
#
# Staff name resolution applies a priority chain: NWC name > MIDI instrument
# name > positional fallback.  Duplicate names must be disambiguated.

subtest 'Transaction 11: part name resolution priority chain' => sub {
	# "Staff" matches the generic default pattern -> should fall through
	# to MIDI name.  We supply a MIDI instrument name to confirm the fallback.
	# We also include a real name and a second real name to test disambiguation.
	my $nwctxt = _nwctxt(
		"|AddStaff|Name:\"Violin\"\n"
		. "|Clef|Type:Treble\n"
		. "|StaffInstrument|Patch:40|Name:\"Violin\"\n"
		. "|Key|Signature:Concert\n"
		. "|TimeSig|Signature:4/4\n"
		. "|Note|Dur:Whole|Pos:0\n"
		. "|Bar|\n"
		. "|AddStaff|Name:\"Violin\"\n"       # duplicate -> both become positional
		. "|Clef|Type:Treble\n"
		. "|StaffInstrument|Patch:41|Name:\"Violin II\"\n"
		. "|Key|Signature:Concert\n"
		. "|TimeSig|Signature:4/4\n"
		. "|Note|Dur:Whole|Pos:0\n"
		. "|Bar|\n"
	);

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	my $xml   = _gen($score);

	# Because both staves have the same NWC name "Violin", the resolver must
	# replace both with positional fallbacks "Staff-1" / "Staff-2".
	like $xml, qr/<part-name>Staff-1<\/part-name>/,
		'Tx11: duplicate name deduped to Staff-1';
	like $xml, qr/<part-name>Staff-2<\/part-name>/,
		'Tx11: duplicate name deduped to Staff-2';

	# "Violin" must not appear as a part-name (it was deduped)
	unlike $xml, qr/<part-name>Violin<\/part-name>/,
		'Tx11: original duplicate name Violin not used as part-name';
};

# ============================================================================
# Transaction 12: convert() overwrite=0 skips existing output (no re-convert)
# ============================================================================
#
# When the output file already exists and overwrite is false, convert() must
# return the existing path without re-running the pipeline.  The file must not
# be modified (mtime-based check).

subtest 'Transaction 12: overwrite=0 skips existing output -- idempotent short-circuit' => sub {
	my $outdir = tempdir(CLEANUP => 1);
	my $src    = _write_valid_nwc($TREBLE_ONE_BAR);
	my $xmlout = File::Spec->catfile($outdir, 'idempotent' . $OUTPUT_EXT);

	my $c = _quiet_converter();

	# First convert: creates the file
	my $r1 = $c->convert(input => $src->filename, output => $xmlout, overwrite => 1);
	is $r1, $xmlout, 'Tx12 run1: convert returns output path';
	ok -f $xmlout,   'Tx12 run1: output file created';

	my $mtime1 = (stat $xmlout)[9];
	sleep 1;   # ensure mtime would differ if file were rewritten

	# Second convert with overwrite=0: must skip (file already exists)
	my $r2 = $c->convert(input => $src->filename, output => $xmlout, overwrite => 0);
	is $r2, $xmlout, 'Tx12 run2: convert returns path for skipped file';

	my $mtime2 = (stat $xmlout)[9];
	is $mtime2, $mtime1,
		'Tx12 run2: output file mtime unchanged (pipeline was not re-run)';
};

# ============================================================================
# Transaction 13: Score object is immutable across generate calls
# ============================================================================
#
# Calling generate() twice on the same Score must produce identical XML and
# must not mutate the Score's staff count or event lists.

subtest 'Transaction 13: generate does not mutate the Score (immutability)' => sub {
	my $score = _parse($THREE_STAVES);

	my $staff_count_before = $score->staff_count;
	my @event_counts_before = map { $_->event_count } @{ $score->staves };

	my $xml1 = _gen($score);
	my $xml2 = _gen($score);

	is $xml2, $xml1, 'Tx13: second generate call produces identical XML';

	is $score->staff_count, $staff_count_before,
		'Tx13: staff_count unchanged after two generate calls';

	my @event_counts_after = map { $_->event_count } @{ $score->staves };
	is_deeply \@event_counts_after, \@event_counts_before,
		'Tx13: per-staff event counts unchanged after two generate calls';
};

done_testing;
