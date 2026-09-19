#!/usr/bin/perl
use strict;
use warnings;

use Test::Most;
use Carp qw(croak);
use Compress::Zlib ();
use Readonly;
use Scalar::Util qw(blessed);

use lib 'lib';
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Event;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Diagnostics;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $NWC_MAGIC      => '[NWZ]';
Readonly::Scalar my $NWCTXT_MARKER  => '!NoteWorthyComposer(';
Readonly::Scalar my $ZLIB_CMF       => 0x78;
Readonly::Scalar my $ZLIB_FLG       => 0x9C;   # (0x78*256 + 0x9C) % 31 == 0
Readonly::Scalar my $MIN_FILE_BYTES => 9;
Readonly::Scalar my $MAX_DECOMP_BYTES => 256 * 1024 * 1024;
Readonly::Scalar my $INPUT_NWC      => 't/input/Pilgrim.nwc';

# Minimal valid NWCTXT payload
Readonly::Scalar my $NWCTXT_MINIMAL =>
	"!NoteWorthyComposer(2.751)\n" .
	"|SongInfo|Title:Test\n" .
	"|AddStaff\n" .
	"|Clef|Type:Treble\n" .
	"|TimeSig|Signature:4/4\n" .
	"|Note|Dur:4th|Pos:0\n" .
	"|Bar\n" .
	"!NoteWorthyComposer-End\n";

# ---------------------------------------------------------------------------
# Helper: build a minimal valid NWC binary payload
# ---------------------------------------------------------------------------
sub _make_nwc_binary {
	my ($nwctxt) = @_;
	$nwctxt //= $NWCTXT_MINIMAL;
	my $compressed = Compress::Zlib::compress(\$nwctxt);
	return $NWC_MAGIC . $compressed;
}

# ---------------------------------------------------------------------------
# 1. NWC::decode -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'NWC::decode -- path: undef data -> croak error_truncated' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode(undef) },
		qr/File appears truncated/,
		'undef data triggers error_truncated',
	);
};

subtest 'NWC::decode -- path: too short (< MIN_FILE_BYTES) -> croak error_truncated' => sub {
	my $short = $NWC_MAGIC . 'x';   # 6 bytes, < 9
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($short) },
		qr/File appears truncated/,
		'6-byte payload triggers error_truncated',
	);

	# BVA: exactly 8 bytes (MIN_FILE_BYTES - 1)
	my $eight = 'x' x ($MIN_FILE_BYTES - 1);
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($eight) },
		qr/File appears truncated/,
		'8-byte payload triggers error_truncated',
	);
};

subtest 'NWC::decode -- path: wrong magic -> croak error_not_nwc' => sub {
	# 9 bytes, not starting with [NWZ]
	my $bad_magic = 'BADHDR' . 'x' x 3;
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($bad_magic) },
		qr/Not a valid NWC file/,
		'wrong magic triggers error_not_nwc',
	);
};

subtest 'NWC::decode -- path: no zlib stream -> croak error_no_zlib_stream' => sub {
	# Valid magic followed by null bytes -- no CMF=0x78 byte
	my $no_zlib = $NWC_MAGIC . "\x00" x 20;
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($no_zlib) },
		qr/No compressed data stream found/,
		'no zlib header triggers error_no_zlib_stream',
	);
};

subtest 'NWC::decode -- path: decompress fail -> croak error_decompress_fail' => sub {
	# Valid magic, valid CMF/FLG pair but corrupt compressed data
	my $corrupt = $NWC_MAGIC . chr($ZLIB_CMF) . chr($ZLIB_FLG) . ("\xff" x 30);
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($corrupt) },
		qr/Decompression failed/,
		'corrupt zlib data triggers error_decompress_fail',
	);
};

subtest 'NWC::decode -- path: no NWCTXT marker -> croak error_no_nwctxt_marker' => sub {
	# Compress data that does NOT contain the NWC marker
	my $plain = 'This is not an NWC file at all.';
	my $compressed = Compress::Zlib::compress(\$plain);
	my $no_marker = $NWC_MAGIC . $compressed;
	throws_ok(
		sub { Music::NWC2MusicXML::NWC->decode($no_marker) },
		qr/NWCTXT marker not found/,
		'missing NWCTXT marker triggers error_no_nwctxt_marker',
	);
};

subtest 'NWC::decode -- path: success (valid binary)' => sub {
	SKIP: {
		skip 'Pilgrim.nwc not found', 1 unless -f $INPUT_NWC;
		my $nwctxt = Music::NWC2MusicXML::NWC->read($INPUT_NWC);
		ok(defined $nwctxt, 'decode succeeds and returns defined string');
		like($nwctxt, qr/\Q$NWCTXT_MARKER\E/, 'result contains NWCTXT marker');
	}
};

subtest 'NWC::decode -- path: success (in-memory binary)' => sub {
	my $nwc_bin = _make_nwc_binary($NWCTXT_MINIMAL);
	my $result;
	lives_ok(
		sub { $result = Music::NWC2MusicXML::NWC->decode($nwc_bin) },
		'in-memory decode does not croak',
	);
	like($result, qr/\Q$NWCTXT_MARKER\E/, 'result starts with NWCTXT marker');
};

# ---------------------------------------------------------------------------
# 2. Event::new -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'Event::new -- path: known musical type -> success' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Note');
	is($ev->type, 'Note', 'musical type stored correctly');
};

subtest 'Event::new -- path: known metadata type -> success' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(type => 'SongInfo');
	is($ev->type, 'SongInfo', 'metadata type stored correctly');
};

subtest 'Event::new -- path: unknown type -> carp, stored as UnsupportedEvent' => sub {
	my $ev;
	warning_like(
		sub { $ev = Music::NWC2MusicXML::Event->new(type => 'FutureNWCObject') },
		qr/Unknown event type/,
		'unknown type produces carp warning',
	);
	is($ev->type, 'UnsupportedEvent', 'unknown type stored as UnsupportedEvent');
	is($ev->nwc_label, 'FutureNWCObject', 'nwc_label preserves original type name');
};

subtest 'Event::new -- path: undef type -> carp, stored as UnsupportedEvent' => sub {
	my $ev;
	warning_like(
		sub { $ev = Music::NWC2MusicXML::Event->new(type => undef) },
		qr/Unknown event type/,
		'undef type produces carp warning',
	);
	is($ev->type, 'UnsupportedEvent', 'undef type stored as UnsupportedEvent');
};

subtest 'Event::new -- path: invalid start_time rational -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->new(type => 'Note', start_time => 'not_an_array') },
		qr/arrayref|Rational arguments/i,
		'non-arrayref start_time triggers croak',
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Event->new(type => 'Note', start_time => [1, 0]) },
		qr/Rational arguments/,
		'zero denominator in start_time triggers croak',
	);
};

subtest 'Event::new -- path: invalid duration rational -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->new(type => 'Note', duration => []) },
		qr/Rational arguments/,
		'empty arrayref duration triggers croak',
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 2, 3]) },
		qr/Rational arguments/,
		'3-element duration triggers croak',
	);
};

subtest 'Event::new -- path: all defaults -> success with [0,1]' => sub {
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Rest');
	is_deeply($ev->start_time, [0, 1], 'default start_time is [0,1]');
	is_deeply($ev->duration,   [0, 1], 'default duration is [0,1]');
	is_deeply($ev->data,       {},     'default data is empty hashref');
};

# ---------------------------------------------------------------------------
# 3. Event::rational_from_nwc_duration -- loop path analysis
# ---------------------------------------------------------------------------

Readonly::Scalar my $DOTS_ZERO => 0;
Readonly::Scalar my $DOTS_ONE  => 1;
Readonly::Scalar my $DOTS_TWO  => 2;

subtest 'rational_from_nwc_duration -- path: dots=0 (loop never executes)' => sub {
	# for my $d (1..0) -> no iterations
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', $DOTS_ZERO);
	is_deeply($r, [1, 1], 'quarter note, no dots = [1,1]');

	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Whole', $DOTS_ZERO);
	is_deeply($r, [4, 1], 'whole note, no dots = [4,1]');
};

subtest 'rational_from_nwc_duration -- path: dots=1 (loop executes exactly once)' => sub {
	# for my $d (1..1) -> exactly 1 iteration
	# Dotted quarter: 1/1 + 1/2 = 3/2
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', $DOTS_ONE);
	is_deeply($r, [3, 2], 'dotted quarter = [3,2]');

	# Dotted half: 2/1 + 1/1 = 3/1
	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', $DOTS_ONE);
	is_deeply($r, [3, 1], 'dotted half = [3,1]');
};

subtest 'rational_from_nwc_duration -- path: dots=2 (loop executes twice)' => sub {
	# for my $d (1..2) -> 2 iterations
	# Double-dotted quarter: 1/1 + 1/2 + 1/4 = 7/4
	my $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', $DOTS_TWO);
	is_deeply($r, [7, 4], 'double-dotted quarter = [7,4]');

	# Double-dotted half: 2/1 + 1/1 + 1/2 = 7/2
	$r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('Half', $DOTS_TWO);
	is_deeply($r, [7, 2], 'double-dotted half = [7,2]');
};

subtest 'rational_from_nwc_duration -- path: invalid duration -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_from_nwc_duration('Quarter') },
		qr/Unrecognised NWC duration/,
		"'Quarter' is not a valid NWC duration name",
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_from_nwc_duration(undef) },
		qr/Unrecognised NWC duration/,
		'undef duration triggers croak',
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_from_nwc_duration('whole') },
		qr/Unrecognised NWC duration/,
		"wrong-case 'whole' triggers croak",
	);
};

# ---------------------------------------------------------------------------
# 4. Event::rational_to_float -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'rational_to_float -- path: valid arrayref -> float' => sub {
	my $f = Music::NWC2MusicXML::Event->rational_to_float([3, 2]);
	is($f, 1.5, '[3,2] -> 1.5');
};

subtest 'rational_to_float -- path: numerator=0 -> 0.0 (BVA boundary)' => sub {
	my $f = Music::NWC2MusicXML::Event->rational_to_float([0, 1]);
	is($f, 0.0, '[0,1] -> 0.0');
};

subtest 'rational_to_float -- path: non-arrayref -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_to_float('1/2') },
		qr/Rational arguments/,
		'scalar string triggers croak',
	);
};

subtest 'rational_to_float -- path: 1-element array -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_to_float([1]) },
		qr/Rational arguments/,
		'1-element array triggers croak',
	);
};

subtest 'rational_to_float -- path: 3-element array -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_to_float([1, 2, 3]) },
		qr/Rational arguments/,
		'3-element array triggers croak',
	);
};

subtest 'rational_to_float -- path: denominator=0 -> croak' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Event->rational_to_float([1, 0]) },
		qr/Rational arguments/,
		'zero denominator triggers croak',
	);
};

# ---------------------------------------------------------------------------
# 5. Event::_gcd (via rational_add) -- loop iteration paths
# ---------------------------------------------------------------------------

subtest '_gcd via rational_add -- path: result is already reduced (loop=1 iter)' => sub {
	# _gcd(3, 2): while b != 0: a,b = 2, 1; then a,b = 1, 0 -> 2 iters -> gcd=1
	my $r = Music::NWC2MusicXML::Event->rational_add([1, 2], [1, 3]);
	is_deeply($r, [5, 6], '[1/2] + [1/3] = [5/6] (no reduction needed)');
};

subtest '_gcd via rational_add -- path: result is reducible (loop runs multiple iters)' => sub {
	# _gcd(6, 4): a,b = 4,2; then a,b = 2,0 -> 2 iters -> gcd=2; 6/2=3, 4/2=2
	my $r = Music::NWC2MusicXML::Event->rational_add([1, 2], [1, 2]);
	is_deeply($r, [1, 1], '[1/2] + [1/2] = [1/1]');

	# _gcd(9, 6) -> gcd=3
	$r = Music::NWC2MusicXML::Event->rational_add([3, 4], [3, 4]);
	is_deeply($r, [3, 2], '[3/4] + [3/4] = [3/2]');
};

subtest '_gcd -- path: b=0 initially means a is result (via _reduce_rational([0,1]))' => sub {
	# When numerator=0, _reduce_rational([0, N]) calls _gcd(0, N)
	# _gcd(0, 1): while 1!=0: a,b = 1, 0%1=0 -> gcd=1 (1 iteration)
	# Then [0/1, 1/1] = [0, 1]
	my $ev = Music::NWC2MusicXML::Event->new(type => 'Rest', duration => [0, 1]);
	is_deeply($ev->duration, [0, 1], '_reduce_rational([0,1]) = [0,1]');
};

# ---------------------------------------------------------------------------
# 6. Score -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'Score::new -- path: no args -> success with empty defaults' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	ok(defined $score, 'Score constructed without args');
	is($score->staff_count, 0, 'empty score has 0 staves');
	is_deeply($score->metadata, {}, 'metadata defaults to {}');
};

subtest 'Score::add_staff -- path: valid Staff -> appended, count increments' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new;
	$score->add_staff($staff);
	is($score->staff_count, 1, 'staff_count is 1 after add_staff');
	is($score->current_staff, $staff, 'current_staff returns just-added staff');
};

subtest 'Score::add_staff -- path: invalid -> croak error_bad_staff' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	throws_ok(
		sub { $score->add_staff('not a staff') },
		qr/add_staff/,
		'non-object triggers croak',
	);
	throws_ok(
		sub { $score->add_staff({}) },
		qr/add_staff/,
		'unblessed hashref triggers croak',
	);
	throws_ok(
		sub { $score->add_staff(bless {}, 'SomeOtherClass') },
		qr/add_staff/,
		'wrong blessed class triggers croak',
	);
};

subtest 'Score::current_staff -- path: empty score -> undef' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	is($score->current_staff, undef, 'empty score current_staff is undef');
};

subtest 'Score::validate -- path: no staves -> returns diagnostic' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	my $diags = $score->validate;
	ok(scalar @$diags > 0, 'validate returns at least one diagnostic for empty score');
	like($diags->[0], qr/no staves/i, 'diagnostic mentions no staves');
};

subtest 'Score::validate -- path: has staves -> returns empty diagnostics' => sub {
	my $score = Music::NWC2MusicXML::Score->new;
	$score->add_staff(Music::NWC2MusicXML::Staff->new);
	my $diags = $score->validate;
	is(scalar @$diags, 0, 'validate returns no diagnostics for non-empty score');
};

# ---------------------------------------------------------------------------
# 7. Staff -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'Staff::add_event -- path: valid Event -> appended' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	my $ev    = Music::NWC2MusicXML::Event->new(type => 'Note');
	$staff->add_event($ev);
	is($staff->event_count, 1, 'event_count is 1 after add_event');
};

subtest 'Staff::add_event -- path: non-Event -> croak error_bad_event' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	throws_ok(
		sub { $staff->add_event(undef) },
		qr/add_event/,
		'undef triggers croak',
	);
	throws_ok(
		sub { $staff->add_event({}) },
		qr/add_event/,
		'unblessed hashref triggers croak',
	);
	throws_ok(
		sub { $staff->add_event(bless {}, 'NotAnEvent') },
		qr/add_event/,
		'wrong class triggers croak',
	);
};

subtest 'Staff::has_notes -- path: empty event list -> false' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	ok(!$staff->has_notes, 'empty staff has_notes is false');
};

subtest 'Staff::has_notes -- path: Tempo events only -> false (non-sounding)' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Tempo',
		data => { bpm => 120, base => 'Quarter' }));
	ok(!$staff->has_notes, 'staff with only Tempo events has_notes is false');
};

subtest 'Staff::has_notes -- path: has Note -> true (early return on first match)' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note'));
	ok($staff->has_notes, 'staff with Note event has_notes is true');
};

subtest 'Staff::has_notes -- path: has Rest -> true' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Rest'));
	ok($staff->has_notes, 'staff with Rest event has_notes is true');
};

subtest 'Staff::has_notes -- path: has Bar -> true' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Bar'));
	ok($staff->has_notes, 'staff with Bar event has_notes is true');
};

subtest 'Staff::has_notes -- path: Tempo then Note -> true (match on second event)' => sub {
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Tempo',
		data => { bpm => 100, base => 'Quarter' }));
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note'));
	ok($staff->has_notes, 'staff with Tempo+Note has_notes is true');
};

# ---------------------------------------------------------------------------
# 8. Diagnostics -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'Diagnostics::new -- path: no args -> defaults to normal level' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new;
	ok(defined $d, 'Diagnostics constructed without args');
};

subtest 'Diagnostics::new -- path: each valid level -> success' => sub {
	for my $level (qw(quiet normal verbose debug)) {
		lives_ok(
			sub { Music::NWC2MusicXML::Diagnostics->new(level => $level) },
			"level='$level' is accepted",
		);
	}
};

subtest 'Diagnostics::new -- path: invalid level -> croak error_internal' => sub {
	throws_ok(
		sub { Music::NWC2MusicXML::Diagnostics->new(level => 'QUIET') },
		qr/Unknown log level/,
		"'QUIET' (wrong case) triggers croak",
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Diagnostics->new(level => '') },
		qr/Unknown log level/,
		"empty string level triggers croak",
	);
	throws_ok(
		sub { Music::NWC2MusicXML::Diagnostics->new(level => '0') },
		qr/Unknown log level/,
		"numeric string '0' triggers croak",
	);
};

subtest 'Diagnostics::count -- path: valid outcome -> increments counter' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	$d->count(outcome => 'processed');
	$d->count(outcome => 'processed');
	$d->count(outcome => 'successful');
	is($d->{_counts}{processed},  2, 'processed counter incremented to 2');
	is($d->{_counts}{successful}, 1, 'successful counter incremented to 1');
};

subtest 'Diagnostics::count -- path: invalid outcome -> croak error_internal' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok(
		sub { $d->count(outcome => 'Processed') },   # wrong case
		qr/Unknown counter/,
		"wrong-case 'Processed' triggers croak",
	);
	throws_ok(
		sub { $d->count(outcome => 'invalid') },
		qr/Unknown counter/,
		"unrecognised outcome triggers croak",
	);
};

subtest 'Diagnostics::_record_warning -- path: with warnings_fh -> writes to handle' => sub {
	my $buf = '';
	open my $fh, '>', \$buf;
	my $d = Music::NWC2MusicXML::Diagnostics->new(
		level       => 'quiet',
		warnings_fh => $fh,
	);
	$d->warn_unsupported(file => 'x.nwc', staff => '1', object => 'Widget');
	close $fh;
	like($buf, qr/WARNING:/, 'warning written to warnings_fh');
	is(scalar @{ $d->warnings }, 1, 'warning recorded in internal list');
};

subtest 'Diagnostics::_record_warning -- path: no warnings_fh -> only internal list' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	# Redirect STDERR to suppress output
	open my $old_err, '>&', \*STDERR;
	open STDERR, '>', '/dev/null';
	$d->warn_unsupported(file => 'x.nwc', staff => '1', object => 'Widget');
	open STDERR, '>&', $old_err;
	close $old_err;
	is(scalar @{ $d->warnings }, 1, 'warning recorded in list even without fh');
};

# ---------------------------------------------------------------------------
# 9. Parser::parse -- control-flow paths
# ---------------------------------------------------------------------------

subtest 'Parser::parse -- path: undef input -> croak error_empty_input' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	throws_ok(
		sub { $p->parse(undef) },
		qr/NWCTXT input is empty/,
		'undef input triggers error_empty_input',
	);
};

subtest 'Parser::parse -- path: empty string -> croak error_empty_input' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	throws_ok(
		sub { $p->parse('') },
		qr/NWCTXT input is empty/,
		'empty string triggers error_empty_input',
	);
};

subtest 'Parser::parse -- path: no header -> croak error_no_header' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	throws_ok(
		sub { $p->parse("NotAValidHeader\n|SomeRecord\n") },
		qr/header/i,
		'missing NWCTXT header triggers error_no_header',
	);
};

subtest 'Parser::parse -- path: valid NWCTXT -> returns Score' => sub {
	my $p     = Music::NWC2MusicXML::Parser->new;
	my $score = $p->parse($NWCTXT_MINIMAL);
	ok(blessed($score) && $score->isa('Music::NWC2MusicXML::Score'), 'parse returns Score');
	ok($score->staff_count >= 1, 'score has at least one staff');
};

# ---------------------------------------------------------------------------
# 10. Parser::_dispatch_record -- branch paths (tested via parse)
# ---------------------------------------------------------------------------

subtest '_dispatch_record -- path: empty/blank line -> silently skipped' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $nwctxt = "!NoteWorthyComposer(2.0)\n\n   \n|AddStaff\n|Note|Dur:4th|Pos:0\n|Bar\n";
	my $score;
	lives_ok(sub { $score = $p->parse($nwctxt) }, 'blank lines do not croak');
	ok($score->staff_count >= 1, 'score still has staves after blank lines');
};

subtest '_dispatch_record -- path: known record type -> dispatched to handler' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $nwctxt = "!NoteWorthyComposer(2.0)\n|SongInfo|Title:Dispatched\n|AddStaff\n|Note|Dur:4th|Pos:0\n|Bar\n";
	my $score  = $p->parse($nwctxt);
	is($score->metadata->{Title}, 'Dispatched', 'SongInfo dispatched and metadata set');
};

subtest '_dispatch_record -- path: unknown type with staff -> UnsupportedEvent stored' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	my $nwctxt = "!NoteWorthyComposer(2.0)\n|AddStaff\n|FutureObject|Param:Value\n|Note|Dur:4th|Pos:0\n|Bar\n";
	my $score;
	warning_like(
		sub { $score = $p->parse($nwctxt) },
		qr/Unknown/i,
		'unknown type within staff produces warning',
	);
	my $events = $score->staves->[0]->events;
	my @unsupported = grep { $_->type eq 'UnsupportedEvent' } @$events;
	ok(scalar @unsupported >= 1, 'UnsupportedEvent stored in staff event list');
};

subtest '_dispatch_record -- path: unknown type before any staff -> silently skipped' => sub {
	my $p = Music::NWC2MusicXML::Parser->new;
	# Score-level record (before AddStaff) that is not in dispatch table
	my $nwctxt = "!NoteWorthyComposer(2.0)\n|Editor|ActiveStaff:1\n|AddStaff\n|Note|Dur:4th|Pos:0\n|Bar\n";
	my $score;
	lives_ok(
		sub { $score = $p->parse($nwctxt) },
		'unrecognised pre-staff record silently skipped',
	);
};

# ---------------------------------------------------------------------------
# 11. Parser::_fifths_from_signature -- all branch paths
# ---------------------------------------------------------------------------

subtest '_fifths_from_signature -- path: undef -> returns 0' => sub {
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature(undef),
		0,
		'undef signature returns 0',
	);
};

subtest '_fifths_from_signature -- path: empty string -> returns 0' => sub {
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature(''),
		0,
		'empty string returns 0',
	);
};

subtest '_fifths_from_signature -- path: natural key -> returns 0' => sub {
	# KEY_SIG_NATURAL is used for C major
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature('No Sharps or Flats'),
		0,
		'natural key signature returns 0',
	);
};

subtest '_fifths_from_signature -- path: sharps -> positive count' => sub {
	# G major = 1 sharp (F#)
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature('F#'),
		1,
		'1 sharp = fifths 1',
	);
	# D major = 2 sharps (F#, C#)
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature('F#,C#'),
		2,
		'2 sharps = fifths 2',
	);
};

subtest '_fifths_from_signature -- path: flats -> negative count' => sub {
	# F major = 1 flat (Bb)
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature('Bb'),
		-1,
		'1 flat = fifths -1',
	);
	# Bb major = 2 flats (Bb, Eb)
	is(
		Music::NWC2MusicXML::Parser::_fifths_from_signature('Bb,Eb'),
		-2,
		'2 flats = fifths -2',
	);
};

# ---------------------------------------------------------------------------
# 12. MusicXML::_xml_escape -- all branch paths
# ---------------------------------------------------------------------------

subtest '_xml_escape -- path: undef -> empty string' => sub {
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape(undef),
		'',
		'undef input returns empty string',
	);
};

subtest '_xml_escape -- path: pure ASCII, no special chars -> passthrough' => sub {
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape('Hello World'),
		'Hello World',
		'plain ASCII passes through unchanged',
	);
};

subtest '_xml_escape -- path: XML special chars -> escaped' => sub {
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape('<tag>&"\''),
		'&lt;tag&gt;&amp;&quot;&apos;',
		'< > & " \' are all escaped',
	);
};

subtest '_xml_escape -- path: control chars -> stripped' => sub {
	my $with_nul  = "Before\x00After";
	my $with_ctrl = "A\x01B\x07C";
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape($with_nul),
		'BeforeAfter',
		'NUL byte stripped',
	);
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape($with_ctrl),
		'ABC',
		'control chars x01 and x07 stripped',
	);
};

subtest '_xml_escape -- path: non-ASCII (multibyte) -> numeric entity' => sub {
	my $umlaut = "\x{e9}";   # e-acute
	is(
		Music::NWC2MusicXML::MusicXML::_xml_escape($umlaut),
		'&#233;',
		'e-acute converted to numeric entity &#233;',
	);
};

# ---------------------------------------------------------------------------
# 13. MusicXML::_pos_to_pitch -- accidental prefix branches
# ---------------------------------------------------------------------------

{
	my $xml = Music::NWC2MusicXML::MusicXML->new;

	subtest '_pos_to_pitch -- path: no accidental prefix (key alter applied)' => sub {
		my $r = $xml->_pos_to_pitch('0', 'Treble', 0);
		is($r->{accidental}, undef, 'no explicit accidental when prefix absent');
		ok(defined $r->{step},   'step is defined');
		ok(defined $r->{octave}, 'octave is defined');
	};

	subtest '_pos_to_pitch -- path: # prefix -> sharp' => sub {
		my $r = $xml->_pos_to_pitch('#0', 'Treble', 0);
		is($r->{accidental}, 'sharp', 'single # -> sharp');
		is($r->{alter},       1,      'alter=1 for sharp');
	};

	subtest '_pos_to_pitch -- path: ## prefix -> double-sharp' => sub {
		my $r = $xml->_pos_to_pitch('##0', 'Treble', 0);
		is($r->{accidental}, 'double-sharp', '## -> double-sharp');
		is($r->{alter},       2,             'alter=2 for double-sharp');
	};

	subtest '_pos_to_pitch -- path: x prefix -> double-sharp' => sub {
		my $r = $xml->_pos_to_pitch('x0', 'Treble', 0);
		is($r->{accidental}, 'double-sharp', 'x -> double-sharp');
		is($r->{alter},       2,             'alter=2 for x');
	};

	subtest '_pos_to_pitch -- path: b prefix -> flat' => sub {
		my $r = $xml->_pos_to_pitch('b0', 'Treble', 0);
		is($r->{accidental}, 'flat', 'b -> flat');
		is($r->{alter},      -1,    'alter=-1 for flat');
	};

	subtest '_pos_to_pitch -- path: bb prefix -> double-flat' => sub {
		my $r = $xml->_pos_to_pitch('bb0', 'Treble', 0);
		is($r->{accidental}, 'double-flat', 'bb -> double-flat');
		is($r->{alter},      -2,            'alter=-2 for double-flat');
	};

	subtest '_pos_to_pitch -- path: n prefix -> natural' => sub {
		my $r = $xml->_pos_to_pitch('n0', 'Treble', 0);
		is($r->{accidental}, 'natural', 'n -> natural');
		is($r->{alter},       0,        'alter=0 for natural');
	};

	subtest '_pos_to_pitch -- path: unrecognised prefix -> key alter, no accidental' => sub {
		# A prefix that is not '', '#', '##', 'x', 'b', 'bb', 'n'
		# _pos_to_pitch falls through to else: $alter=$key_alt, $accidental=undef
		# Actually let me check what prefix triggers the else
		# Regex: /^([#bnx]*)(-?\d+)\^?$/ -- only # b n x are valid prefix chars
		# If prefix is 'z' it won't match the regex at all -> ($acc_prefix, $pos_num) stay ('', 0)
		# So there's no path for "unrecognised" prefix that reaches the else branch
		# The else IS reachable: a prefix like '#b' would match but not equal any known pattern
		my $r = $xml->_pos_to_pitch('#b0', 'Treble', 0);
		is($r->{accidental}, undef, '#b (unrecognised combo) falls to else -> no accidental');
	};

	subtest '_pos_to_pitch -- path: negative octave correction branch' => sub {
		# pos_num = -100 on Treble: index = 3*7 + 5 + (-100) = 26 - 100 = -74
		# int(-74/7) = -10 (rounds toward zero), but -74 = -10*7 + (-4)
		# so we need floor division: -10 - 1 = -11? Let's just check it doesn't crash
		my $r = $xml->_pos_to_pitch('-20', 'Treble', 0);
		ok(defined $r->{octave}, 'extreme negative position still produces defined octave');
	};
}

# ---------------------------------------------------------------------------
# 14. MusicXML::_emit_dynamic -- branch paths
# ---------------------------------------------------------------------------

{
	my $xml = Music::NWC2MusicXML::MusicXML->new;

	subtest '_emit_dynamic -- path: empty string -> silent return (no output)' => sub {
		my @out = $xml->_emit_dynamic('', 'above', '');
		is(scalar @out, 0, 'empty marking returns empty list (no output)');
	};

	subtest '_emit_dynamic -- path: unknown marking -> carp, returns empty' => sub {
		my @out;
		warning_like(
			sub { @out = $xml->_emit_dynamic('zzz', 'above', '') },
			qr/Unrecognised dynamic marking/i,
			'unknown marking produces warning',
		);
		is(scalar @out, 0, 'unknown marking returns empty list');
	};

	subtest '_emit_dynamic -- path: valid marking -> returns XML lines' => sub {
		my @out = $xml->_emit_dynamic('mf', 'above', '');
		ok(scalar @out > 0, 'valid marking returns non-empty list');
		like(join('', @out), qr/<direction/, 'output contains <direction> element');
		like(join('', @out), qr/<mf\/>/, 'output contains <mf/> dynamics element');
	};

	subtest '_emit_dynamic -- path: placement above vs below' => sub {
		my @out_above = $xml->_emit_dynamic('p', 'above', '');
		my @out_below = $xml->_emit_dynamic('p', 'below', '');
		like(join('', @out_above), qr/placement="above"/, 'above placement in output');
		like(join('', @out_below), qr/placement="below"/, 'below placement in output');
	};
}

# ---------------------------------------------------------------------------
# 15. MusicXML::_emit_wedge -- branch paths
# ---------------------------------------------------------------------------

{
	my $xml = Music::NWC2MusicXML::MusicXML->new;

	subtest '_emit_wedge -- path: unknown style -> returns empty' => sub {
		my @out = $xml->_emit_wedge('UnknownStyle', 'above', '');
		is(scalar @out, 0, 'unknown wedge style returns empty list');
	};

	subtest '_emit_wedge -- path: Crescendo -> crescendo wedge' => sub {
		my @out = $xml->_emit_wedge('Crescendo', 'above', '');
		ok(scalar @out > 0, 'Crescendo returns XML lines');
		like(join('', @out), qr/type="crescendo"/, 'crescendo type in output');
	};

	subtest '_emit_wedge -- path: crescOff -> stop wedge' => sub {
		my @out = $xml->_emit_wedge('crescOff', 'above', '');
		like(join('', @out), qr/type="stop"/, 'crescOff produces stop wedge');
	};
}

# ---------------------------------------------------------------------------
# 16. MusicXML::_calculate_divisions -- loop path analysis
# ---------------------------------------------------------------------------

subtest '_calculate_divisions -- path: no staves -> returns DEFAULT_DIVISIONS' => sub {
	my $xml   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	my $divs  = $xml->_calculate_divisions($score);
	ok(defined $divs && $divs > 0, 'returns positive integer for empty score');
};

subtest '_calculate_divisions -- path: single denominator (loop 0 iterations)' => sub {
	# All events have duration [1,1] -> @denoms = (1): inner for loop executes 0 times
	my $xml   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 1]));
	$score->add_staff($staff);
	my $divs = $xml->_calculate_divisions($score);
	is($divs, 1, 'single denom=1 -> divisions=1');
};

subtest '_calculate_divisions -- path: two distinct denominators (loop 1 iteration)' => sub {
	# Quarter [1,1] and eighth [1,2]: LCM(1,2)=2 -> inner for loop executes once
	my $xml   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 1]));
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 2]));
	$score->add_staff($staff);
	my $divs = $xml->_calculate_divisions($score);
	is($divs, 2, 'quarter+eighth: LCM(1,2)=2');
};

subtest '_calculate_divisions -- path: three distinct denominators (loop 2 iterations)' => sub {
	# Quarter [1,1], eighth [1,2], sixteenth [1,4]: LCM(1,2,4)=4
	my $xml   = Music::NWC2MusicXML::MusicXML->new;
	my $score = Music::NWC2MusicXML::Score->new;
	my $staff = Music::NWC2MusicXML::Staff->new;
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 1]));
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 2]));
	$staff->add_event(Music::NWC2MusicXML::Event->new(type => 'Note', duration => [1, 4]));
	$score->add_staff($staff);
	my $divs = $xml->_calculate_divisions($score);
	is($divs, 4, 'quarter+eighth+sixteenth: LCM(1,2,4)=4');
};

# ---------------------------------------------------------------------------
done_testing;
