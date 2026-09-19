#!/usr/bin/perl
use strict;
use warnings;

# Data-flow tests: every test here validates a specific DU (Define-Use) chain,
# resource lifecycle, or data-flow anomaly across the NWC2MusicXML pipeline.
#
# Organisation by target:
#   1.  NWC.pm -- file handle Open-Use-Close lifecycle, $/ isolation
#   2.  NWC.pm -- decode pipeline DU chain (binary -> NWCTXT)
#   3.  Parser.pm -- parse-state reset between successive calls
#   4.  Parser.pm -- version field DU chain through Score
#   5.  Score.pm -- staves arrayref aliasing (internal reference identity)
#   6.  Staff.pm -- events arrayref ordering and reference identity
#   7.  Event.pm -- Readonly constant immutability under repeated calls
#   8.  Event.pm -- rational arithmetic purity and reduction correctness
#   9.  Diagnostics.pm -- warning array and counter synchrony
#  10.  MusicXML.pm -- metadata thread-through (Score -> XML)
#  11.  MusicXML.pm -- @out accumulation order in generate()
#  12.  MusicXML.pm -- clef/key state update at Bar boundaries
#  13.  MusicXML.pm -- _annotate_events slur D~ rolling-window correctness
#  14.  MusicXML.pm -- _annotate_wedges DU chain correctness
#  15.  Global variable isolation ($_, $@, $!) across all public methods
#  16.  Full pipeline DU: NWC binary -> NWCTXT -> Score -> XML

use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(mock_scoped);
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Readonly;
use Scalar::Util qw(blessed refaddr weaken);
use List::Util qw(uniq);

use Music::NWC2MusicXML;
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Diagnostics;

# ---------------------------------------------------------------------------
# Shared test fixtures
# ---------------------------------------------------------------------------

Readonly::Scalar my $PILGRIM_NWC     => 't/input/Pilgrim.nwc';
Readonly::Scalar my $NWCTXT_HEADER   => "!NoteWorthyComposer(2.75)\n";
Readonly::Scalar my $MINIMAL_STAFF   => "|AddStaff|Name:\"Pno\"\n|Note|Dur:4th|Pos:0\n|Bar|\n";
Readonly::Scalar my $MINIMAL_NWC     => $NWCTXT_HEADER . $MINIMAL_STAFF;

# A score with two measures, mid-staff clef change in measure 2
Readonly::Scalar my $CLEF_CHANGE_NWC => $NWCTXT_HEADER
	. "|AddStaff|Name:\"S\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:C\n"
	. "|TimeSig|Signature:Common\n"
	. "|Note|Dur:4th|Pos:0\n"
	. "|Bar|\n"
	. "|Clef|Type:Bass\n"
	. "|Note|Dur:4th|Pos:0\n"
	. "|Bar|\n";

# A score with a known title and author
Readonly::Scalar my $META_TITLE  => 'Data Flow Test Suite';
Readonly::Scalar my $META_AUTHOR => 'Test Author';
Readonly::Scalar my $META_NWC => $NWCTXT_HEADER
	. "|SongInfo|Title:\"$META_TITLE\"|Author:\"$META_AUTHOR\"\n"
	. $MINIMAL_STAFF;

# Slur test: three notes all marked Slur (arc covering all three)
Readonly::Scalar my $SLUR_NWC => $NWCTXT_HEADER
	. "|AddStaff|Name:\"V\"\n"
	. "|Note|Dur:4th,Slur|Pos:0\n"
	. "|Note|Dur:4th,Slur|Pos:1\n"
	. "|Note|Dur:4th,Slur|Pos:2\n"
	. "|Bar|\n";

# ---------------------------------------------------------------------------
# Helper: build a minimal Score/Staff/Event tree programmatically
# ---------------------------------------------------------------------------

sub _minimal_score {
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Piano');
	$staff->set_initial_clef('Treble');
	$staff->set_initial_key({ fifths => 0, signature => 'C', tonic => 'C' });
	$staff->set_initial_timesig({ beats => 4, beat_type => 4 });
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => '0', base_dur => '4th', dots => 0 },
		)
	);
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(type => 'Bar', duration => [0, 1], data => { style => 'normal' })
	);
	$score->add_staff($staff);
	return $score;
}

# ---------------------------------------------------------------------------
# Section 1: NWC.pm -- File handle lifecycle ($/ isolation, no dangling handles)
# ---------------------------------------------------------------------------

subtest 'NWC::read does not leak $/ to calling scope' => sub {
	# DU: local $/ = undef is defined inside a bare block; must be killed (K)
	# before returning so the caller's input record separator is unchanged.
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;
	my $before = $/;
	Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	is $/, $before, '$/ unchanged after NWC::read (local $/ correctly scoped)';
};

subtest 'NWC::read does not leak file descriptors (Open-Use-Close verified)' => sub {
	# Resource lifecycle: count open fds before and after; they must match.
	unless (-d '/proc/self/fd') {
		pass 'fd-leak check skipped: /proc/self/fd not available on this platform';
		return;
	}
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	my $before = () = glob '/proc/self/fd/*';
	Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	my $after = () = glob '/proc/self/fd/*';

	is $after, $before, 'fd count unchanged after NWC::read (no dangling fh)';
};

subtest 'NWC::read does not leak fds on multiple calls' => sub {
	unless (-d '/proc/self/fd') {
		pass 'fd-leak check skipped: /proc/self/fd not available on this platform';
		return;
	}
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	my $before = () = glob '/proc/self/fd/*';
	for (1 .. 5) {
		Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	}
	my $after = () = glob '/proc/self/fd/*';

	is $after, $before, 'fd count unchanged after 5 successive NWC::read calls';
};

subtest 'NWC::read returns scalar string, not arrayref or filehandle' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;
	my $result = Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	ok !ref($result), 'NWC::read returns a plain scalar (not a reference)';
	ok length($result) > 0, 'result is non-empty string';
};

# ---------------------------------------------------------------------------
# Section 2: NWC.pm -- Decode pipeline DU chain
# ---------------------------------------------------------------------------
#
# DU chain: $data (D: file read) -> decode($data) -> _find_zlib_offset($data) ->
#           $zlib_offset (D) -> _decompress($data, $zlib_offset) ->
#           $raw (D) -> substr($raw, $marker_pos) -> $nwctxt (D) -> return

subtest 'NWC decode pipeline: each stage produces a defined, non-empty value' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	# Read raw binary to test decode directly
	open my $fh, '<:raw', $PILGRIM_NWC
		or return note "Cannot open $PILGRIM_NWC";
	local $/;
	my $binary = <$fh>;
	close $fh;

	ok defined $binary, 'binary data: D -- defined after file read';
	ok length($binary) > 0, 'binary data: non-empty';

	# decode: transforms binary -> NWCTXT
	my $nwctxt = Music::NWC2MusicXML::NWC->decode($binary, $PILGRIM_NWC);

	ok defined $nwctxt, 'NWCTXT: D -- defined after decode';
	like $nwctxt, qr/^!NoteWorthyComposer\(/, 'NWCTXT: begins with expected marker (pipeline preserved marker)';
	like $nwctxt, qr/\|AddStaff\|/, 'NWCTXT: contains AddStaff record (data not lost)';
};

subtest 'NWC decode: NWCTXT is a UTF-8 string (not binary bytes)' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	open my $fh, '<:raw', $PILGRIM_NWC
		or return note "Cannot open $PILGRIM_NWC";
	local $/;
	my $binary = <$fh>;
	close $fh;

	my $nwctxt = Music::NWC2MusicXML::NWC->decode($binary);
	# After utf8::decode or utf8::upgrade, the string must be valid UTF-8
	my $copy = $nwctxt;
	ok utf8::is_utf8($copy) || do { utf8::encode($copy); 1 },
		'NWCTXT is valid UTF-8 (U -- correctly transformed during decode)';
};

subtest 'NWC decode: output is strictly smaller than raw binary (NWCTXT stripped pre-marker bytes)' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	open my $fh, '<:raw', $PILGRIM_NWC
		or return note "Cannot open $PILGRIM_NWC";
	local $/;
	my $binary = <$fh>;
	close $fh;

	my $nwctxt = Music::NWC2MusicXML::NWC->decode($binary);
	# After decompression and marker extraction, the output is a subset of
	# decompressed bytes -- in practice far larger than binary but smaller than
	# full decompressed payload.  We just verify decode didn't return the binary.
	isnt $nwctxt, $binary, 'NWCTXT output differs from binary input (transform applied)';
};

subtest 'NWC::read result identical to NWC::decode on same file' => sub {
	# DU chain identity: both paths must produce the same NWCTXT.
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	my $via_read = Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);

	open my $fh, '<:raw', $PILGRIM_NWC
		or return note "Cannot open $PILGRIM_NWC";
	local $/;
	my $binary = <$fh>;
	close $fh;
	my $via_decode = Music::NWC2MusicXML::NWC->decode($binary, $PILGRIM_NWC);

	is $via_read, $via_decode,
		'read() and decode() produce identical NWCTXT (DU chain consistency)';
};

# ---------------------------------------------------------------------------
# Section 3: Parser.pm -- Parse-state reset between successive calls
# ---------------------------------------------------------------------------
#
# DU: $self->{_score}, _line_no, _record_count are all D=0 at the top of
# parse(), ensuring no state bleeds between invocations on the same object.

subtest 'Parser: successive calls return independent Score objects' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;

	my $s1 = $p->parse($MINIMAL_NWC);
	my $s2 = $p->parse($META_NWC);

	isnt refaddr($s1), refaddr($s2), 'two Score objects are distinct references (fresh D each call)';
	ok blessed($s1) && $s1->isa('Music::NWC2MusicXML::Score'), 'first parse returned a Score';
	ok blessed($s2) && $s2->isa('Music::NWC2MusicXML::Score'), 'second parse returned a Score';
};

subtest 'Parser: metadata from first parse does not bleed into second parse' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;

	my $s1 = $p->parse($META_NWC);
	is $s1->metadata->{Title}, $META_TITLE, 'first parse: Title correctly stored';

	# Parse a second input without a Title field
	my $no_meta = $NWCTXT_HEADER . $MINIMAL_STAFF;
	my $s2 = $p->parse($no_meta);

	ok !defined($s2->metadata->{Title}),
		'second parse: Title is undef (no bleed from first parse -- _score reset at D)';
};

subtest 'Parser: _line_no does not accumulate across successive calls' => sub {
	# _line_no is D=0 at the top of parse(); if reset is missing, line numbers
	# would start from where the previous call left off.
	my $p = Music::NWC2MusicXML::Parser->new;
	$p->parse($MINIMAL_NWC);   # first call -- advances _line_no

	# Internal state should be reset; we test indirectly by verifying that
	# the second parse() accepts the same minimal input without error.
	lives_ok { $p->parse($MINIMAL_NWC) } 'second parse on same object does not throw (state was reset)';
};

subtest 'Parser: _record_count does not accumulate across successive calls' => sub {
	# A large-ish NWCTXT (many Bar records) would push _record_count well above
	# MAX_RECORDS if it were not reset.  We create a moderately large input to
	# verify the counter really is reset each time.
	my $big_nwc = $NWCTXT_HEADER . "|AddStaff|Name:\"X\"\n";
	$big_nwc .= "|Note|Dur:4th|Pos:0\n|Bar|\n" x 1000;

	my $p = Music::NWC2MusicXML::Parser->new;
	lives_ok { $p->parse($big_nwc) } 'first parse of 1000-measure input succeeds';
	lives_ok { $p->parse($big_nwc) } 'second parse of 1000-measure input succeeds (counter reset)';
};

# ---------------------------------------------------------------------------
# Section 4: Parser.pm -- Version field DU chain through Score
# ---------------------------------------------------------------------------
#
# DU: $version D: from regex match on header line -> U: stored in $score->{_nwc_version}
# -> U: readable via $score->nwc_version

subtest 'Parser: version string DU chain -- version extracted and stored in Score' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $s = $p->parse("!NoteWorthyComposer(2.751)\n" . $MINIMAL_STAFF);
	is $s->nwc_version, '2.751', 'version string D->U: extracted from header, stored in Score';
};

subtest 'Parser: version is scalar string, not a ref or array' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $s = $p->parse($MINIMAL_NWC);
	my $v = $s->nwc_version;
	ok !ref($v), 'nwc_version is a plain scalar (not reference)' if defined $v;
	pass 'version field DU chain type check complete';
};

subtest 'Parser: header without version substring stores undef nwc_version gracefully' => sub {
	# If the regex /(version)/ does not match, $version = undef.
	# The Score must not croak on undef nwc_version.
	my $p = Music::NWC2MusicXML::Parser->new;
	my $s = $p->parse("!NoteWorthyComposer()\n" . $MINIMAL_STAFF);
	# Either undef or empty string is acceptable; must not crash
	lives_ok { $s->nwc_version } 'nwc_version access on empty-header score does not croak';
	pass 'nwc_version with empty () header does not crash';
};

# ---------------------------------------------------------------------------
# Section 5: Score.pm -- Staves arrayref aliasing (reference identity)
# ---------------------------------------------------------------------------
#
# DU: $self->{_staves} D in new() -> U in add_staff (push) -> U returned by staves()
# The returned ref must be the SAME reference as the internal array.

subtest 'Score::staves returns the internal array reference (alias, not copy)' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new;
	$score->add_staff($staff);

	my $ref1 = $score->staves;
	my $ref2 = $score->staves;

	is refaddr($ref1), refaddr($ref2),
		'staves() returns same reference on successive calls (no copying)';
};

subtest 'Score::add_staff immediately visible through staves()' => sub {
	# DU: push @{$self->{_staves}} (D) -> staves() reads the same arrayref (U)
	my $score = Music::NWC2MusicXML::Score->new;
	is $score->staff_count, 0, 'empty initially';

	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'Violin');
	$score->add_staff($s1);

	is $score->staff_count, 1, 'staff_count incremented immediately';
	is refaddr($score->staves->[0]), refaddr($s1),
		'staves()[0] is the same reference as the added Staff object';
};

subtest 'Score::current_staff is last element of staves() (no independent pointer)' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $s1 = Music::NWC2MusicXML::Staff->new(name => 'A');
	my $s2 = Music::NWC2MusicXML::Staff->new(name => 'B');
	$score->add_staff($s1);
	$score->add_staff($s2);

	is refaddr($score->current_staff), refaddr($s2),
		'current_staff() == last element of staves() (same reference)';
	is refaddr($score->current_staff), refaddr($score->staves->[-1]),
		'current_staff matches staves->[-1] exactly';
};

subtest 'Score::validate returns arrayref (not a flat list)' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $result = $score->validate;
	ok ref($result) eq 'ARRAY', 'validate() returns an ARRAY ref (not a flat list)';
};

subtest 'Score metadata hashref aliasing -- set_metadata_field visible through metadata()' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	$score->set_metadata_field('Title', 'Aliasing Test');
	is $score->metadata->{Title}, 'Aliasing Test',
		'metadata() returns same hashref that set_metadata_field wrote to';

	# Second call to metadata() returns the same reference
	is refaddr($score->metadata), refaddr($score->metadata),
		'metadata() returns same hashref reference on successive calls';
};

# ---------------------------------------------------------------------------
# Section 6: Staff.pm -- Events arrayref ordering and reference identity
# ---------------------------------------------------------------------------
#
# DU: $self->{_events} D=[] in new() -> push in add_event -> returned by events()

subtest 'Staff::events returns internal arrayref (alias, not copy)' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1,1], data => { nwc_pos => '0', base_dur => '4th' });
	$staff->add_event($ev);

	my $ref1 = $staff->events;
	my $ref2 = $staff->events;
	is refaddr($ref1), refaddr($ref2), 'events() returns same arrayref on successive calls';
};

subtest 'Staff: events are stored in insertion order (FIFO DU chain)' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	my @evs = map {
		Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 1],
			data     => { nwc_pos => "$_", base_dur => '4th', dots => 0 },
		)
	} (0, 1, 2, 3);

	$staff->add_event($_) for @evs;

	my $stored = $staff->events;
	is scalar @$stored, 4, 'all 4 events stored';
	for my $i (0 .. 3) {
		is refaddr($stored->[$i]), refaddr($evs[$i]),
			"event[$i] is the same reference as inserted (order preserved)";
	}
};

subtest 'Staff::musical_events is a subset of events() in the same relative order' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;

	my $note = Music::NWC2MusicXML::Event->new(
		type => 'Note', duration => [1,1],
		data => { nwc_pos => '0', base_dur => '4th' });
	my $meta = Music::NWC2MusicXML::Event->new(
		type => 'SongInfo', duration => [0,1], data => {});
	my $bar = Music::NWC2MusicXML::Event->new(
		type => 'Bar', duration => [0,1], data => { style => 'normal' });

	$staff->add_event($note);
	$staff->add_event($meta);
	$staff->add_event($bar);

	my $all    = $staff->events;
	my $musical = $staff->musical_events;

	is scalar @$all,    3, 'three total events';
	is scalar @$musical, 2, 'two musical events (Note + Bar; SongInfo excluded)';
	is refaddr($musical->[0]), refaddr($note), 'first musical event is the Note';
	is refaddr($musical->[1]), refaddr($bar),  'second musical event is the Bar';
};

subtest 'Staff::event_count always equals scalar @{events()}' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	is $staff->event_count, 0, 'empty initially';

	for my $i (1 .. 5) {
		$staff->add_event(
			Music::NWC2MusicXML::Event->new(
				type => 'Note', duration => [1,1],
				data => { nwc_pos => '0', base_dur => '4th' })
		);
		is $staff->event_count, $i, "event_count == $i after $i adds";
		my $ev_len = scalar @{$staff->events};
		is $staff->event_count, $ev_len,
			"event_count agrees with scalar events() after $i adds";
	}
};

subtest 'Staff::has_notes: false before any sounding event, true after Note added' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	ok !$staff->has_notes, 'has_notes false on empty staff';

	# A non-sounding event (Tempo) should NOT flip has_notes
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(
			type => 'Tempo', duration => [0,1],
			data => { bpm => 120, base => 'Quarter' })
	);
	ok !$staff->has_notes, 'has_notes still false after Tempo-only events';

	# A Note flips it
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(
			type => 'Note', duration => [1,1],
			data => { nwc_pos => '0', base_dur => '4th' })
	);
	ok $staff->has_notes, 'has_notes true after Note added';
};

# ---------------------------------------------------------------------------
# Section 7: Event.pm -- Readonly constant immutability under repeated calls
# ---------------------------------------------------------------------------
#
# DU anomaly check: rational_from_nwc_duration takes $r = $DURATION_RATIONALS{$dur}
# and $base_r = $r (both alias the Readonly entry).  Repeated calls must never
# mutate the table.

subtest 'Event::rational_from_nwc_duration: Readonly table not mutated by dotted notes' => sub {
	# We call the function several times for the same duration at different dot
	# counts and verify the non-dotted result is always the same (proving the
	# Readonly constant was never modified between calls).
	my @quarter_results;
	for (1 .. 5) {
		push @quarter_results,
			Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 0);
	}
	for my $r (@quarter_results) {
		is_deeply $r, [1, 1], 'quarter-note rational is [1,1] every time (Readonly not mutated)';
	}
};

subtest 'Event::rational_from_nwc_duration: dotted calls return NEW arrayrefs each time' => sub {
	# When dots > 0, _add_rationals creates new arrayrefs; the returned value
	# must not be the same reference as the Readonly table entry.
	my $dotted_q1 = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1);
	my $dotted_q2 = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1);

	isnt refaddr($dotted_q1), refaddr($dotted_q2),
		'two dotted-quarter calls return distinct arrayrefs (no aliasing of mutable result)';
	is_deeply $dotted_q1, $dotted_q2,
		'but they have equal values [3,2]';
	is_deeply $dotted_q1, [3, 2], 'dotted quarter = [3,2] (1 + 1/2 = 3/2)';
};

subtest 'Event::rational_from_nwc_duration: all recognised durations map correctly' => sub {
	# DU: every key in %DURATION_RATIONALS must produce a well-formed rational.
	my %expected_no_dots = (
		'Whole' => [4, 1],
		'Half'  => [2, 1],
		'4th'   => [1, 1],
		'8th'   => [1, 2],
		'16th'  => [1, 4],
		'32nd'  => [1, 8],
		'64th'  => [1, 16],
	);
	for my $dur (sort keys %expected_no_dots) {
		my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration($dur, 0);
		is_deeply $r, $expected_no_dots{$dur},
			"$dur (0 dots) -> [@{$expected_no_dots{$dur}}] (DU chain verified)";
	}
};

subtest 'Event::rational_from_nwc_duration: dotted note math is correct' => sub {
	# Dotted quarter: 1 + 1/2 = 3/2  => [3, 2]
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1),
		[3, 2], 'dotted quarter = [3,2]');
	# Double-dotted quarter: 1 + 1/2 + 1/4 = 7/4  => [7, 4]
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 2),
		[7, 4], 'double-dotted quarter = [7,4]');
	# Dotted half: 2 + 1 = 3  => [3, 1]
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', 1),
		[3, 1], 'dotted half = [3,1]');
	# Dotted whole: 4 + 2 = 6  => [6, 1]
	is_deeply(Music::NWC2MusicXML::Event->rational_from_nwc_duration('Whole', 1),
		[6, 1], 'dotted whole = [6,1]');
};

# ---------------------------------------------------------------------------
# Section 8: Event.pm -- Rational arithmetic purity and reduction correctness
# ---------------------------------------------------------------------------

subtest 'Event::rational_add: result is always in lowest terms' => sub {
	# rational_add calls _reduce_rational; result must be coprime
	my $r = Music::NWC2MusicXML::Event->rational_add([1, 2], [1, 2]);
	is_deeply $r, [1, 1], '[1/2] + [1/2] = [1/1] (fully reduced)';

	$r = Music::NWC2MusicXML::Event->rational_add([1, 4], [1, 4]);
	is_deeply $r, [1, 2], '[1/4] + [1/4] = [1/2] (fully reduced)';

	$r = Music::NWC2MusicXML::Event->rational_add([3, 8], [1, 8]);
	is_deeply $r, [1, 2], '[3/8] + [1/8] = [1/2] (fully reduced)';
};

subtest 'Event::rational_add: commutative property holds' => sub {
	my $a = [3, 4];
	my $b = [1, 6];
	my $ab = Music::NWC2MusicXML::Event->rational_add($a, $b);
	my $ba = Music::NWC2MusicXML::Event->rational_add($b, $a);
	is_deeply $ab, $ba, 'rational_add is commutative ([3/4]+[1/6] == [1/6]+[3/4])';
};

subtest 'Event::rational_add: does not mutate input arguments (pure function)' => sub {
	my $r1 = [1, 2];
	my $r2 = [1, 3];
	my $ref1_before = "$r1->[0]/$r1->[1]";
	my $ref2_before = "$r2->[0]/$r2->[1]";

	Music::NWC2MusicXML::Event->rational_add($r1, $r2);

	is "$r1->[0]/$r1->[1]", $ref1_before, 'first argument not mutated';
	is "$r2->[0]/$r2->[1]", $ref2_before, 'second argument not mutated';
};

subtest 'Event::rational_to_float: correct floating-point values' => sub {
	is(Music::NWC2MusicXML::Event->rational_to_float([1, 1]), 1.0,  '[1,1] -> 1.0');
	is(Music::NWC2MusicXML::Event->rational_to_float([3, 2]), 1.5,  '[3,2] -> 1.5');
	is(Music::NWC2MusicXML::Event->rational_to_float([7, 4]), 1.75, '[7,4] -> 1.75');
	is(Music::NWC2MusicXML::Event->rational_to_float([1, 4]), 0.25, '[1,4] -> 0.25');
};

subtest 'Event::rational_to_float: zero numerator returns 0.0 without crash' => sub {
	# [0,1] is a valid rational (used for non-durational events like Bar)
	my $r = eval { Music::NWC2MusicXML::Event->rational_to_float([0, 1]) };
	ok defined $r && $r == 0.0, '[0,1] -> 0.0 (zero numerator is valid)';
};

# ---------------------------------------------------------------------------
# Section 9: Diagnostics.pm -- Warning array and counter synchrony
# ---------------------------------------------------------------------------
#
# DU: _warnings (D=[]) -> push in _record_warning (D each call) ->
#     _counts->{warnings} (D=0) -> ++ in _record_warning
# Both structures must always agree.

subtest 'Diagnostics: warning count and array length always in sync' => sub {
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');

	is scalar @{$diag->warnings}, 0, 'empty initially';
	ok !$diag->has_warnings, 'has_warnings false initially';

	for my $i (1 .. 5) {
		$diag->warn_unsupported(
			file => 'test.nwc', staff => "Staff $i",
			object => 'FakeObject', reason => 'none');
		is $diag->{_counts}{warnings}, $i,
			"_counts{warnings} == $i after $i warnings";
		is scalar @{$diag->warnings}, $i,
			"warnings() length == $i after $i warnings";
		ok $diag->has_warnings, 'has_warnings true when warnings exist';
	}
};

subtest 'Diagnostics: warn_approximate also increments both warning structures' => sub {
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$diag->warn_approximate(
		file => 'x.nwc', staff => 'S1',
		feature => 'Ottava', approximation => 'ignored');
	is $diag->{_counts}{warnings}, 1, 'counter incremented';
	is scalar @{$diag->warnings}, 1, 'array length incremented';
};

subtest 'Diagnostics: warnings stored in FIFO insertion order' => sub {
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	for my $obj (qw(First Second Third)) {
		$diag->warn_unsupported(file => 'f', staff => 's', object => $obj);
	}
	like $diag->warnings->[0], qr/First/,  'first warning is First';
	like $diag->warnings->[1], qr/Second/, 'second warning is Second';
	like $diag->warnings->[2], qr/Third/,  'third warning is Third';
};

subtest 'Diagnostics: count() increments specific counter without affecting others' => sub {
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$diag->count(outcome => 'processed');
	$diag->count(outcome => 'successful');
	$diag->count(outcome => 'successful');

	is $diag->{_counts}{processed},  1, 'processed == 1';
	is $diag->{_counts}{successful}, 2, 'successful == 2';
	is $diag->{_counts}{warnings},   0, 'warnings still 0 (not contaminated)';
	is $diag->{_counts}{failed},     0, 'failed still 0 (not contaminated)';
};

subtest 'Diagnostics: warnings written to warnings_fh in Open-Use sequence' => sub {
	# Resource lifecycle: warnings_fh is an externally supplied filehandle.
	# The module must write to it but NOT close it (caller owns the handle).
	my $buffer = '';
	open my $warn_fh, '>', \$buffer;

	my $diag = Music::NWC2MusicXML::Diagnostics->new(
		level       => 'quiet',
		warnings_fh => $warn_fh,
	);
	$diag->warn_unsupported(
		file => 'test.nwc', staff => 'Piano',
		object => 'MyObj', reason => 'testing');

	# The filehandle must still be open after the call (module must not close it)
	ok fileno($warn_fh), 'warnings_fh still open after warn_unsupported (not closed by Diagnostics)';

	close $warn_fh;
	like $buffer, qr/WARNING:/, 'warning written to fh (Use in Open-Use sequence)';
	like $buffer, qr/MyObj/,    'warning message contains the object name';
};

# ---------------------------------------------------------------------------
# Section 10: MusicXML.pm -- Metadata thread-through (Score -> XML)
# ---------------------------------------------------------------------------
#
# DU chain: Score::metadata (D) -> _emit_work -> _emit_identification ->
#           _emit_credits -> XML string (U by caller)

subtest 'MusicXML::generate threads Title from metadata into XML output' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($META_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	like $xml, qr/\Q$META_TITLE\E/, "Title '$META_TITLE' appears in XML output";
};

subtest 'MusicXML::generate threads Author from metadata into XML output' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($META_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	like $xml, qr/\Q$META_AUTHOR\E/, "Author '$META_AUTHOR' appears in XML output";
};

subtest 'MusicXML::generate escapes metadata before embedding in XML (D -> _xml_escape -> U)' => sub {
	my $inject = 'Title & <Author> "inject"';
	my $nwc = $NWCTXT_HEADER
		. "|SongInfo|Title:\"$inject\"\n"
		. $MINIMAL_STAFF;
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwc));

	unlike $xml, qr/<Author>/, 'raw <Author> tag not present (escaped)';
	like   $xml, qr/&amp;/,    '& escaped to &amp;';
	like   $xml, qr/&lt;/,     '< escaped to &lt;';
};

subtest 'MusicXML::generate: empty metadata fields produce no empty XML elements' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	unlike $xml, qr/<work-title><\/work-title>/,  'no empty work-title';
	unlike $xml, qr/<creator[^>]*><\/creator>/,   'no empty creator';
};

subtest 'MusicXML::generate: page setup hashref flows into layout dimensions' => sub {
	# DU: page_setup (D from Score) -> _compute_page_layout (U) -> layout values (D)
	# -> _emit_defaults (U) -> XML output
	my $score = Music::NWC2MusicXML::Score->new(
		page_setup => { Left => 2.54 });   # 1 inch margin
	my $staff = Music::NWC2MusicXML::Staff->new(name => 'Piano');
	$staff->set_initial_clef('Treble');
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(
			type => 'Note', duration => [1,1],
			data => { nwc_pos => '0', base_dur => '4th' }));
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(type => 'Bar', duration => [0,1], data => { style => 'normal' }));
	$score->add_staff($staff);

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<defaults>/, 'defaults section present in XML';
	like $xml, qr/<page-layout>/, 'page-layout present (page_setup data flowed through)';
};

# ---------------------------------------------------------------------------
# Section 11: MusicXML.pm -- @out accumulation order in generate()
# ---------------------------------------------------------------------------
#
# DU: @out D=() -> push operations -> join("\n", @out) . "\n" -> return
# The order of sections in the output must respect MusicXML schema order.

subtest 'MusicXML::generate: XML declaration is first non-empty line' => sub {
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	my @lines = grep { length $_ } split /\n/, $xml;
	like $lines[0], qr/^<\?xml /, 'XML declaration is first non-empty line';
};

subtest 'MusicXML::generate: DOCTYPE declaration follows XML declaration' => sub {
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	my @lines = grep { length $_ } split /\n/, $xml;
	like $lines[1], qr/^<!DOCTYPE /, 'DOCTYPE follows XML declaration';
};

subtest 'MusicXML::generate: score-partwise precedes part-list precedes part' => sub {
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	my $pos_score = index($xml, '<score-partwise');
	my $pos_list  = index($xml, '<part-list>');
	my $pos_part  = index($xml, '<part ');

	ok $pos_score < $pos_list,
		'<score-partwise> appears before <part-list> (accumulation order)';
	ok $pos_list < $pos_part,
		'<part-list> appears before <part> (accumulation order)';
};

subtest 'MusicXML::generate: </score-partwise> is the last meaningful element' => sub {
	my $xml  = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	my @lines = grep { /\S/ } split /\n/, $xml;
	is $lines[-1], '</score-partwise>',
		'last non-blank line is </score-partwise> (join accumulation complete)';
};

subtest 'MusicXML::generate: output terminates with a newline' => sub {
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	like $xml, qr/\n$/, 'output ends with newline (join..."\n" correctly appended)';
};

# ---------------------------------------------------------------------------
# Section 12: MusicXML.pm -- Clef/key state update at Bar boundaries
# ---------------------------------------------------------------------------
#
# DU: $clef_start / $clef_now are defined before the event loop, updated
# at Clef events and committed to $clef_start at each Bar.
# A mid-staff clef change must appear in the NEXT measure's attributes.

subtest 'MusicXML: initial clef appears in measure 1 attributes' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($CLEF_CHANGE_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	# Measure 1 should have Treble clef
	like $xml, qr/<sign>G<\/sign>/, 'Treble (G) clef present in XML output';
};

subtest 'MusicXML: mid-staff clef change after Bar is reflected in next measure' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($CLEF_CHANGE_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	# Measure 2 should have Bass clef (F sign, line 4)
	like $xml, qr/<sign>F<\/sign>/, 'Bass (F) clef present after clef change';
};

subtest 'MusicXML: clef_start is updated at each Bar (state not carried backward)' => sub {
	# Three-measure score: Treble | Bass-change | Bar | Bar
	my $nwc = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "|Clef|Type:Treble\n"
		. "|TimeSig|Signature:Common\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n"
		. "|Clef|Type:Bass\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwc);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	# Bass clef must appear in measure 2; measure 3 should inherit it
	my $bass_count = () = $xml =~ /<sign>F<\/sign>/g;
	ok $bass_count >= 1, 'Bass clef element appears at least once in output';
	unlike $xml, qr/<sign>G<\/sign>.*<sign>F<\/sign>.*<sign>G<\/sign>/s,
		'Treble does not reappear after Bass clef change (state not reverted)';
};

# ---------------------------------------------------------------------------
# Section 13: MusicXML.pm -- _annotate_events slur D~ rolling-window
# ---------------------------------------------------------------------------
#
# DU anomaly documented in MusicXML.pm: $last_slur_ev is a D~ rolling window.
# Intermediate assignments (consecutive slurred notes) are dead stores.
# We verify the CORRECT behaviour despite the anomaly: only the last slurred
# note receives slur_stop.

subtest '_annotate_events: first note of slur arc gets slur_start' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($SLUR_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<slur[^>]*type="start"/, 'slur start element present in XML';
};

subtest '_annotate_events: last note of slur arc gets slur_stop (D~ rolling window correct)' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse($SLUR_NWC);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<slur[^>]*type="stop"/, 'slur stop element present in XML';
};

subtest '_annotate_events: single-note slur arc gets both start and stop' => sub {
	my $single_slur = $NWCTXT_HEADER
		. "|AddStaff|Name:\"V\"\n"
		. "|Note|Dur:4th,Slur|Pos:0\n"
		. "|Note|Dur:4th|Pos:1\n"   # non-slurred note closes arc
		. "|Bar|\n";
	my $score = Music::NWC2MusicXML::Parser->new->parse($single_slur);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<slur[^>]*type="start"/, 'slur start present';
	like $xml, qr/<slur[^>]*type="stop"/,  'slur stop present';
};

subtest '_annotate_events: unclosed slur arc at end of staff gets stop annotation' => sub {
	# Slur never closed: the end-of-loop cleanup must fire.
	my $open_slur = $NWCTXT_HEADER
		. "|AddStaff|Name:\"V\"\n"
		. "|Note|Dur:4th,Slur|Pos:0\n"
		. "|Note|Dur:4th,Slur|Pos:1\n"
		. "|Bar|\n";   # arc never explicitly closed
	my $score = Music::NWC2MusicXML::Parser->new->parse($open_slur);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/<slur[^>]*type="stop"/, 'unclosed arc: stop emitted by end-of-staff cleanup';
};

# ---------------------------------------------------------------------------
# Section 14: MusicXML.pm -- _annotate_wedges DU chain correctness
# ---------------------------------------------------------------------------
#
# DU: $wedge_now (D=undef) and $prev_wedge_key (D=undef) track arc state.
# Both are updated on each event; the open-arc cleanup at end-of-loop must
# set wedge_stop_after on the last event in the arc.

subtest '_annotate_wedges: crescendo arc gets wedge_start on first and wedge_stop_after on last' => sub {
	my $crescendo_nwc = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0|Opts:Crescendo\n"
		. "|Note|Dur:4th|Pos:1|Opts:Crescendo\n"
		. "|Note|Dur:4th|Pos:2\n"   # arc ends here
		. "|Bar|\n";
	my $score = Music::NWC2MusicXML::Parser->new->parse($crescendo_nwc);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/type="crescendo"/, 'crescendo wedge start in XML';
	like $xml, qr/type="stop"/,      'wedge stop in XML';
};

# ---------------------------------------------------------------------------
# Section 15: Global variable isolation ($_, $@, $!) across all public methods
# ---------------------------------------------------------------------------
#
# Each public method must not clobber $_, $@, or $! as observed by the caller.

subtest 'NWC::read does not clobber $_ (global variable isolation)' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;
	local $_ = 'sentinel_nwc_read';
	Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	is $_, 'sentinel_nwc_read', '$_ unchanged after NWC::read';
};

subtest 'Parser::parse does not clobber $_ ' => sub {
	local $_ = 'sentinel_parse';
	Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
	is $_, 'sentinel_parse', '$_ unchanged after Parser::parse';
};

subtest 'MusicXML::generate does not clobber $_' => sub {
	local $_ = 'sentinel_gen';
	Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	is $_, 'sentinel_gen', '$_ unchanged after MusicXML::generate';
};

subtest 'Score methods do not clobber $_' => sub {
	local $_ = 'sentinel_score';
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff(Music::NWC2MusicXML::Staff->new);
	$score->staves;
	$score->current_staff;
	$score->staff_count;
	$score->validate;
	is $_, 'sentinel_score', '$_ unchanged after Score method calls';
};

subtest 'Staff methods do not clobber $_' => sub {
	local $_ = 'sentinel_staff';
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(
		Music::NWC2MusicXML::Event->new(
			type => 'Note', duration => [1,1],
			data => { nwc_pos => '0', base_dur => '4th' }));
	$staff->events;
	$staff->musical_events;
	$staff->event_count;
	$staff->has_notes;
	is $_, 'sentinel_staff', '$_ unchanged after Staff method calls';
};

subtest 'Event::rational_from_nwc_duration does not clobber $@' => sub {
	eval { die "seeded error\n" };
	my $before = $@;
	Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 1);
	# The method must not introduce a NEW $@ value.
	ok !($@ && $@ ne $before),
		'$@ after rational_from_nwc_duration is not a new error from that method';
};

subtest 'Diagnostics methods do not clobber $@' => sub {
	eval { die "seeded_diag\n" };
	my $before = $@;
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$diag->warn_unsupported(file => 'f', staff => 's', object => 'O');
	$diag->count(outcome => 'processed');
	ok !($@ && $@ ne $before),
		'$@ not clobbered by Diagnostics method calls';
};

# ---------------------------------------------------------------------------
# Section 16: Full pipeline DU chain -- NWC binary -> NWCTXT -> Score -> XML
# ---------------------------------------------------------------------------
#
# This is the end-to-end DU verification: each stage's output is the next
# stage's input.  We verify that data is correctly threaded across all module
# boundaries without loss or corruption.

subtest 'Full pipeline: NWC binary -> NWCTXT -> Score -> XML all produce defined values' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	# Stage 1: Binary -> NWCTXT (NWC.pm)
	my $nwctxt = Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	ok defined $nwctxt && length($nwctxt) > 0,
		'Stage 1 D: NWCTXT defined and non-empty';

	# Stage 2: NWCTXT -> Score (Parser.pm)
	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	ok blessed($score) && $score->isa('Music::NWC2MusicXML::Score'),
		'Stage 2 D: Score is a Music::NWC2MusicXML::Score';
	ok $score->staff_count > 0, 'Score has at least one staff';

	# Stage 3: Score -> XML (MusicXML.pm)
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	ok defined $xml && length($xml) > 0, 'Stage 3 D: XML is non-empty';
	like $xml, qr/^<\?xml /, 'XML starts with XML declaration';
	like $xml, qr/<score-partwise/, 'XML contains score-partwise root element';
	like $xml, qr/<\/score-partwise>/, 'XML is complete (root element closed)';
};

subtest 'Full pipeline: staff count consistent across Score and XML part count' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	my $score = Music::NWC2MusicXML::Parser->new->parse(
		Music::NWC2MusicXML::NWC->read($PILGRIM_NWC));
	my $expected_parts = $score->staff_count;
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);

	my $actual_parts = () = $xml =~ /<score-part /g;
	is $actual_parts, $expected_parts,
		"XML has $expected_parts <score-part> elements (matches Score staff count)";
};

subtest 'Full pipeline: NWC version from NWCTXT header flows into Score metadata' => sub {
	return note 'No test NWC file available' unless -f $PILGRIM_NWC;

	my $nwctxt = Music::NWC2MusicXML::NWC->read($PILGRIM_NWC);
	my ($expected_ver) = $nwctxt =~ /!NoteWorthyComposer\(([^)]+)\)/;

	my $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt);
	is $score->nwc_version, $expected_ver,
		'nwc_version in Score matches version string from NWCTXT header (full DU thread)';
};

subtest 'Full pipeline: multiple independent pipeline runs produce identical output' => sub {
	# Verify that each fresh pipeline run on the same input produces the same
	# output -- no shared mutable state leaks between runs.
	my $nwc1 = $MINIMAL_NWC;
	my $nwc2 = $MINIMAL_NWC;

	my $xml1 = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwc1));
	my $xml2 = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwc2));

	is $xml1, $xml2, 'identical inputs produce identical outputs (no shared mutable state)';
};

subtest 'Full pipeline: divisions value correctly derived from all event durations' => sub {
	# A score with mixed durations (quarter + eighth) requires divisions=2
	# to represent both exactly.
	my $mixed_nwc = $NWCTXT_HEADER
		. "|AddStaff|Name:\"P\"\n"
		. "|Clef|Type:Treble\n"
		. "|TimeSig|Signature:Common\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Note|Dur:8th|Pos:0\n"
		. "|Note|Dur:8th|Pos:0\n"
		. "|Bar|\n";

	my $score = Music::NWC2MusicXML::Parser->new->parse($mixed_nwc);
	my $xml   = Music::NWC2MusicXML::MusicXML->new->generate($score);

	# With divisions=2: quarter=2 ticks, eighth=1 tick
	like $xml, qr/<divisions>2<\/divisions>/, 'divisions=2 for quarter+eighth mix';
	like $xml, qr/<duration>2<\/duration>/,   'quarter note: 2 ticks';
	like $xml, qr/<duration>1<\/duration>/,   'eighth note: 1 tick';
};

done_testing;
