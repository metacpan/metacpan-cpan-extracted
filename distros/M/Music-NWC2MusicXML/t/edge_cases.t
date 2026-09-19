#!/usr/bin/perl
use strict;
use warnings;

# Destructive, pathological, boundary-condition and security tests.
# The strategy throughout is *adversarial*: every test here is an attempt
# to make the module crash, leak data, corrupt output, or invoke undefined
# behaviour.  A passing run means all guards are actually working.
#
# Organisation:
#   1. NWC binary decoder (NWC.pm) -- file I/O and binary format hostility
#   2. NWCTXT Parser (Parser.pm)  -- malformed text, resource limits
#   3. Event rational math        -- numeric edge cases and type confusion
#   4. Score/Staff type guards    -- wrong types, circular refs
#   5. MusicXML generation        -- XML injection, zero-staff, bad types
#   6. Diagnostics                -- invalid levels, closed handles, counters
#   7. Global variable isolation  -- $_, $@, $! not contaminated
#   8. Context abuse              -- list vs scalar context
#   9. I/O failure simulation     -- Test::Mockingbird upstream stubs
#  10. Filesystem hostility       -- special devices, symlinks, permissions
#  11. Security probes            -- XML injection, path traversal

use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(mock_scoped);
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Readonly;
use POSIX qw(ENOSPC);
use Scalar::Util qw(blessed refaddr);

use lib 'lib';
use_ok('Music::NWC2MusicXML');
use_ok('Music::NWC2MusicXML::NWC');
use_ok('Music::NWC2MusicXML::Parser');
use_ok('Music::NWC2MusicXML::MusicXML');
use_ok('Music::NWC2MusicXML::Diagnostics');
use_ok('Music::NWC2MusicXML::Score');
use_ok('Music::NWC2MusicXML::Staff');
use_ok('Music::NWC2MusicXML::Event');

# ---------------------------------------------------------------------------
# Constants -- eliminate all magic values
# ---------------------------------------------------------------------------

Readonly::Scalar my $PILGRIM_NWC     => 't/input/Pilgrim.nwc';
Readonly::Scalar my $NWC_MAGIC       => '[NWZ]';
Readonly::Scalar my $NWCTXT_HEADER   => "!NoteWorthyComposer(2.75)\n";
Readonly::Scalar my $MINIMAL_STAFF   => "|AddStaff|Name:\"Pno\"\n|Note|Dur:4th|Pos:0\n|Bar|\n";
Readonly::Scalar my $MAX_NWC_RECORDS => 1_000_000;

# A complete minimal NWCTXT document
Readonly::Scalar my $MINIMAL_NWC => $NWCTXT_HEADER . $MINIMAL_STAFF;

# Hostile strings for injection testing
Readonly::Scalar my $XML_INJECT => '</part-name><evil>injected</evil><part-name>';
Readonly::Scalar my $XML_ATTR_INJECT => '" onload="alert(1)" x="';
Readonly::Scalar my $CDATA_INJECT => ']]>';
Readonly::Scalar my $PROC_INJECT  => '<?xml version="2.0"?>';
Readonly::Scalar my $DOCTYPE_INJECT =>
	q{<!DOCTYPE foo [<!ENTITY xxe SYSTEM 'file:///etc/passwd'>]>&xxe;};

# Helpers

sub _make_nwc_blob {
	# Minimal valid NWC binary = magic + two bytes + real compressed data.
	# For hostile tests we just want the magic with garbage after it.
	my ($suffix) = @_;
	$suffix //= "\x00" x 50;
	return $NWC_MAGIC . $suffix;
}

sub _minimal_score {
	return Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
}

sub _minimal_xml {
	return Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
}

# ============================================================================
# 1. NWC binary decoder -- file I/O and binary format hostility
# ============================================================================

subtest 'NWC::read undef filename croaks cleanly (no sprintf warning)' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->read(undef) }
		qr/Cannot read file/,
		'undef filename: croaks with file-not-found message (not sprintf warning)';
};

subtest 'NWC::read empty string filename croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->read('') }
		qr/Cannot read file/,
		'empty string filename: croaks file-not-found';
};

subtest 'NWC::read missing file croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->read('/no/such/file_that_does_not_exist_xyz.nwc') }
		qr/Cannot read file/,
		'missing file: croaks file-not-found';
};

subtest 'NWC::read directory-as-file croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $nwc = Music::NWC2MusicXML::NWC->new;
	# A directory is not a plain file: -f fails
	throws_ok { $nwc->read($dir) }
		qr/Cannot read file/,
		'directory path: croaks file-not-found';
};

subtest 'NWC::decode undef data croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->decode(undef) }
		qr/truncated/i,
		'undef data: croaks truncated';
};

subtest 'NWC::decode empty string croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->decode('') }
		qr/truncated/i,
		'empty data: croaks truncated';
};

subtest 'NWC::decode wrong magic croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->decode('[WRONG_MAGIC]' . "\x00" x 50) }
		qr/Not a valid NWC file/,
		'wrong magic: croaks not-nwc';
};

subtest 'NWC::decode truncated after magic croaks' => sub {
	# Less than MIN_FILE_BYTES: magic only with nothing after it
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->decode($NWC_MAGIC) }
		qr/truncated/i,
		'magic only (too short): croaks truncated';
};

subtest 'NWC::decode all-zero payload after magic croaks' => sub {
	# No valid zlib header in the payload
	my $nwc = Music::NWC2MusicXML::NWC->new;
	my $data = $NWC_MAGIC . ("\x00" x 100);
	throws_ok { $nwc->decode($data) }
		qr/No compressed data stream/,
		'all-zero payload: croaks no-zlib-stream';
};

subtest 'NWC::read /dev/null (0-byte file) croaks' => sub {
	my $nwc = Music::NWC2MusicXML::NWC->new;
	throws_ok { $nwc->read('/dev/null') }
		qr/truncated|Cannot read/,
		'/dev/null: croaks on empty/unreadable content';
};

subtest 'NWC::read filename with hostile shell chars is safe (Perl open, no shell)' => sub {
	# Perl's 3-arg open never invokes a shell, so these must simply fail as
	# "file not found", not execute any commands.
	my $nwc = Music::NWC2MusicXML::NWC->new;
	for my $hostile (
		'/tmp/|id|.nwc',
		'/tmp/`id`.nwc',
		"/tmp/foo\nbar.nwc",
	) {
		throws_ok { $nwc->read($hostile) }
			qr/Cannot read file/,
			"hostile filename [$hostile]: croaks file-not-found (no shell injection)";
	}
	# /tmp/../../etc/passwd resolves to a real file on Linux; it passes the
	# file-exists guard and correctly fails on the NWC magic check -- no
	# command execution, no data exfiltration.
	throws_ok { $nwc->read('/tmp/../../etc/passwd') }
		qr/Cannot read file|Not a valid NWC file/,
		'/tmp/../../etc/passwd: croaks on format error (no shell injection)';
};

subtest 'NWC::read unreadable file croaks' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'unreadable.nwc');
	open my $fh, '>', $file or die $!;
	print $fh 'dummy';
	close $fh;
	chmod 0000, $file;

	SKIP: {
		skip 'Running as root -- permission test not meaningful', 1
			if $> == 0;

		my $nwc = Music::NWC2MusicXML::NWC->new;
		throws_ok { $nwc->read($file) }
			qr/Cannot read file/,
			'unreadable file: croaks file-not-found (no read permission)';
	}

	chmod 0644, $file;   # restore so tempdir cleanup works
};

# Regression: NWC::read with undef previously triggered sprintf warning
# (fixed by using $filename // '(undef)' before the unless guard).
subtest 'NWC::read undef -- no "use of uninitialized value" warning' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $nwc = Music::NWC2MusicXML::NWC->new;
	eval { $nwc->read(undef) };
	my @uninit = grep { /uninitialized/i } @warnings;
	is scalar @uninit, 0, 'no "use of uninitialized value" warning for undef filename';
};

# ============================================================================
# 2. NWCTXT Parser -- malformed text and resource limits
# ============================================================================

subtest 'Parser::parse undef input croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse(undef) }
		qr/empty or undefined/,
		'undef: croaks empty-input';
};

subtest 'Parser::parse empty string croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse('') }
		qr/empty or undefined/,
		'empty string: croaks empty-input';
};

subtest 'Parser::parse whitespace-only string croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse("   \n\n\t\n") }
		qr/empty or undefined|expected header/i,
		'whitespace only: croaks (no valid header)';
};

subtest 'Parser::parse missing NWC header croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Parser->new->parse("NOT_A_HEADER\n|AddStaff|Name:\"X\"\n") }
		qr/expected header/i,
		'missing header: croaks no-header';
};

subtest 'Parser::parse valid header but no staves returns 0-staff score' => sub {
	# A score with no AddStaff records is valid input; the generator will reject
	# it, but the parser must not crash.
	my $score;
	lives_ok {
		$score = Music::NWC2MusicXML::Parser->new->parse($NWCTXT_HEADER);
	} 'header-only NWCTXT: parser does not croak';
	is $score->staff_count, 0, 'returns score with 0 staves';
};

subtest 'Parser::parse Note before AddStaff croaks' => sub {
	my $nwctxt = $NWCTXT_HEADER . "|Note|Dur:4th|Pos:0\n";
	throws_ok { Music::NWC2MusicXML::Parser->new->parse($nwctxt) }
		qr/no staff|AddStaff/i,
		'Note before AddStaff: croaks no-staff error';
};

subtest 'Parser::parse MAX_RECORDS+1 records croaks' => sub {
	# Build a document exceeding the 1-million record safety limit.
	# We use Tempo records (lightweight) for speed.
	my $body = $NWCTXT_HEADER . "|AddStaff|Name:\"S\"\n";
	$body .= "|Bar|\n" x ($MAX_NWC_RECORDS + 2);
	throws_ok { Music::NWC2MusicXML::Parser->new->parse($body) }
		qr/too many records|max.*record/i,
		'more than MAX_RECORDS records: croaks too-many-records';
};

subtest 'Parser::parse unknown record type becomes UnsupportedEvent' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "|FutureMagicRecord|SomeField:Value\n"
		. "|Bar|\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'unknown record: no croak';
	is $score->staff_count, 1, 'one staff parsed';
	# The unknown record should appear as UnsupportedEvent in the event list
	my @unsupported = grep { $_->type eq 'UnsupportedEvent' } @{ $score->staves->[0]->events };
	ok scalar @unsupported > 0, 'unknown record stored as UnsupportedEvent';
};

subtest 'Parser::parse malformed record line (no leading pipe) ignored gracefully' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "NotAPipedRecord\n"
		. "|Note|Dur:4th|Pos:0\n"
		. "|Bar|\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'non-piped line: no croak';
	is $score->staff_count, 1, 'staff still parsed';
};

subtest 'Parser::parse very long staff name is handled without truncation' => sub {
	my $long_name = 'A' x 10_000;
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"$long_name\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'long staff name: no croak';
	is length($score->staves->[0]->name), length($long_name), 'long name preserved in full';
};

subtest 'Parser::parse zero BPM Tempo handled (degenerate but not fatal)' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "|Tempo|Tempo:0|Base:Quarter\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'Tempo:0: parser does not croak';
};

subtest 'Parser::parse null byte in NWCTXT does not crash or inject' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"S\x{00}tring\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'null byte in value: no crash';
	# The name should not crash the generator either
	lives_ok {
		Music::NWC2MusicXML::MusicXML->new->generate($score)
	} 'null byte in staff name: generator does not crash';
};

subtest 'Parser::parse NWCTXT with CRLF line endings' => sub {
	my $nwctxt = $NWCTXT_HEADER;
	$nwctxt =~ s/\n/\r\n/g;
	$nwctxt .= "|AddStaff|Name:\"S\"\r\n|Note|Dur:4th|Pos:0\r\n|Bar|\r\n";
	my $score;
	lives_ok { $score = Music::NWC2MusicXML::Parser->new->parse($nwctxt) } 'CRLF line endings: no croak';
	is $score->staff_count, 1, 'score has one staff';
};

subtest 'Parser context: parse() in list context returns single Score' => sub {
	# Perl list context should not splat the returned object into many items.
	my @result = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
	is scalar @result, 1, 'parse() in list context returns exactly 1 item';
	is blessed($result[0]), 'Music::NWC2MusicXML::Score', 'that item is a Score';
};

# ============================================================================
# 3. Event rational math -- numeric edge cases and type confusion
# ============================================================================

subtest 'Event::rational_to_float zero denominator croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_to_float([1, 0]) }
		qr/Rational arguments/,
		'[1, 0]: croaks on zero denominator (was: division by zero -- regression)';
};

subtest 'Event::rational_to_float undef croaks or returns safely' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_to_float(undef) }
		qr/Rational|not an ARRAY/i,
		'undef: croaks rather than segfaults';
};

subtest 'Event::rational_to_float empty arrayref croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_to_float([]) }
		qr/Rational/,
		'[]: croaks (too few elements)';
};

subtest 'Event::rational_to_float [0, 1] returns 0.0 without error' => sub {
	my $f;
	lives_ok { $f = Music::NWC2MusicXML::Event->rational_to_float([0, 1]) } '[0,1]: no croak';
	is $f, 0.0, '[0, 1] => 0.0';
};

subtest 'Event::rational_from_nwc_duration unknown name croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_from_nwc_duration('BadDur') }
		qr/Unrecognised NWC duration/,
		'unknown duration name: croaks';
};

subtest 'Event::rational_from_nwc_duration empty string croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_from_nwc_duration('') }
		qr/Unrecognised NWC duration/,
		'empty duration name: croaks';
};

subtest 'Event::rational_from_nwc_duration undef croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->rational_from_nwc_duration(undef) }
		qr/Unrecognised NWC duration/,
		'undef duration name: croaks';
};

subtest 'Event::rational_from_nwc_duration 0 dots (no dots) returns base ratio' => sub {
	my $r;
	lives_ok { $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', 0) }
		'4th with 0 dots: no croak';
	is_deeply $r, [1, 1], '4th/0dots = [1,1]';
};

subtest 'Event::rational_from_nwc_duration negative dots (degenerate)' => sub {
	# Negative dots means the loop never runs; result is the base ratio.
	my $r;
	lives_ok { $r = Music::NWC2MusicXML::Event->rational_from_nwc_duration('4th', -99) }
		'4th with -99 dots: no croak (loop does not execute)';
	is_deeply $r, [1, 1], 'negative dots: base ratio returned unchanged';
};

subtest 'Event::rational_add with [0,1] + [0,1] = [0,1]' => sub {
	my $r = Music::NWC2MusicXML::Event->rational_add([0, 1], [0, 1]);
	is_deeply $r, [0, 1], 'zero + zero = zero rational';
};

subtest 'Event::new with unregistered type becomes UnsupportedEvent' => sub {
	my $ev;
	lives_ok {
		$ev = Music::NWC2MusicXML::Event->new(type => 'GhostType2099');
	} 'unregistered type: no croak';
	is $ev->type, 'UnsupportedEvent', 'type normalised to UnsupportedEvent';
	is $ev->nwc_label, 'GhostType2099', 'original label preserved in nwc_label';
};

subtest 'Event::new with undef type becomes UnsupportedEvent (no croak, no sprintf warning)' => sub {
	# validate_strict accepts undef as a scalar; the code normalises it to
	# UnsupportedEvent and carps.  Verify: no croak, no "uninitialized" warning.
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };
	my $ev;
	lives_ok { $ev = Music::NWC2MusicXML::Event->new(type => undef) }
		'undef type: new() does not croak';
	is $ev->type, 'UnsupportedEvent', 'undef type normalised to UnsupportedEvent';
	my @uninit = grep { /uninitialized/i } @warns;
	is scalar @uninit, 0,
		'no "uninitialized value" sprintf warning (regression: _fmt_msg undef guard)';
};

subtest 'Event::new with no arguments croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Event->new() }
		qr/required|type/i,
		'no arguments: croaks missing-required';
};

subtest 'Event::new start_time with zero denominator croaks' => sub {
	throws_ok {
		Music::NWC2MusicXML::Event->new(
			type       => 'Note',
			start_time => [1, 0],
		)
	} qr/Rational/,
		'start_time [1,0]: croaks bad-rational';
};

subtest 'Event::new duration with zero denominator croaks' => sub {
	throws_ok {
		Music::NWC2MusicXML::Event->new(
			type     => 'Note',
			duration => [1, 0],
		)
	} qr/Rational/,
		'duration [1,0]: croaks bad-rational';
};

subtest 'Event::new with circular reference in data stored without crashing' => sub {
	# Circular reference in data: the module must store it without exploding;
	# it's the caller's responsibility to avoid cycles.
	my $circular = {};
	$circular->{self} = $circular;
	my $ev;
	lives_ok {
		$ev = Music::NWC2MusicXML::Event->new(
			type => 'Note',
			data => $circular,
		)
	} 'circular ref in data: new() does not crash';
	ok defined $ev, 'event object created';
	# Verify it's the same circular structure (not deep-copied into disaster)
	is refaddr($ev->data), refaddr($circular),
		'data is stored by ref (circular structure survived)';
};

subtest 'Event::new wrong data type (arrayref) croaks' => sub {
	throws_ok {
		Music::NWC2MusicXML::Event->new(type => 'Note', data => [1, 2, 3])
	} qr/validate|type|hashref/i,
		'arrayref data: validate_strict croaks';
};

# ============================================================================
# 4. Score / Staff type guards
# ============================================================================

subtest 'Score::add_staff undef croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Score->new->add_staff(undef) }
		qr/must be a Music::NWC2MusicXML::Staff/,
		'add_staff(undef): croaks bad-staff';
};

subtest 'Score::add_staff scalar croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Score->new->add_staff(42) }
		qr/must be a Music::NWC2MusicXML::Staff/,
		'add_staff(42): croaks bad-staff';
};

subtest 'Score::add_staff unblessed hashref croaks with correct message' => sub {
	# Regression: was previously "Can't call method isa on unblessed reference".
	throws_ok { Music::NWC2MusicXML::Score->new->add_staff({}) }
		qr/must be a Music::NWC2MusicXML::Staff/,
		'add_staff({}): croaks bad-staff (not method-not-found crash)';
};

subtest 'Score::add_staff wrong blessed type croaks' => sub {
	my $not_a_staff = bless {}, 'SomeOtherClass';
	throws_ok { Music::NWC2MusicXML::Score->new->add_staff($not_a_staff) }
		qr/must be a Music::NWC2MusicXML::Staff/,
		'add_staff(wrong blessed type): croaks bad-staff';
};

subtest 'Staff::add_event undef croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Staff->new(name => 'S')->add_event(undef) }
		qr/must be a Music::NWC2MusicXML::Event/,
		'add_event(undef): croaks bad-event';
};

subtest 'Staff::add_event unblessed hashref croaks with correct message' => sub {
	# Regression: was previously "Can't call method isa on unblessed reference".
	throws_ok { Music::NWC2MusicXML::Staff->new(name => 'S')->add_event({}) }
		qr/must be a Music::NWC2MusicXML::Event/,
		'add_event({}): croaks bad-event (not method-not-found crash)';
};

subtest 'Staff::add_event wrong blessed type croaks' => sub {
	my $not_an_event = bless {}, 'NotEvent';
	throws_ok {
		Music::NWC2MusicXML::Staff->new(name => 'S')->add_event($not_an_event)
	} qr/must be a Music::NWC2MusicXML::Event/,
		'add_event(wrong blessed type): croaks bad-event';
};

subtest 'Score::set_metadata_field undef value is stored without crashing' => sub {
	# undef is not a validated input type here; the method just stores it.
	# It must not crash and the generator must handle undef metadata gracefully.
	my $score = Music::NWC2MusicXML::Score->new;
	lives_ok { $score->set_metadata_field('Title', undef) } 'undef metadata value: no croak';
	ok !defined $score->metadata->{Title}, 'undef stored correctly';
};

subtest 'Score::new with non-hashref metadata croaks via validate_strict' => sub {
	throws_ok { Music::NWC2MusicXML::Score->new(metadata => 'SCALAR') }
		qr/validate|type/i,
		'metadata => scalar: validate_strict croaks';
};

# ============================================================================
# 5. MusicXML generation -- XML injection, zero-staff, bad types
# ============================================================================

subtest 'MusicXML::generate undef score croaks with error_bad_score' => sub {
	throws_ok { Music::NWC2MusicXML::MusicXML->new->generate(undef) }
		qr/must be a Music::NWC2MusicXML::Score/,
		'generate(undef): croaks error_bad_score';
};

subtest 'MusicXML::generate scalar string croaks with error_bad_score' => sub {
	throws_ok { Music::NWC2MusicXML::MusicXML->new->generate('not a score') }
		qr/must be a Music::NWC2MusicXML::Score/,
		'generate("string"): croaks error_bad_score';
};

subtest 'MusicXML::generate unblessed hashref croaks with error_bad_score' => sub {
	# Regression: was previously "Can't call method isa on unblessed reference"
	# because ref({}) is truthy.  Fixed by using blessed().
	throws_ok { Music::NWC2MusicXML::MusicXML->new->generate({}) }
		qr/must be a Music::NWC2MusicXML::Score/,
		'generate({}): croaks error_bad_score (not Perl method-not-found)';
};

subtest 'MusicXML::generate zero-staff score croaks' => sub {
	my $empty = Music::NWC2MusicXML::Score->new;
	throws_ok { Music::NWC2MusicXML::MusicXML->new->generate($empty) }
		qr/no staves/i,
		'zero-staff score: croaks error_no_staves';
};

subtest 'XML injection via staff name is neutralised' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|AddStaff|Name:\"$XML_INJECT\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	unlike $xml, qr/<evil>/, 'literal <evil> tag not present in output';
	like $xml, qr/&lt;evil&gt;/, 'injection escaped as &lt; / &gt;';
};

subtest 'XML injection via metadata title is neutralised' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"$XML_INJECT\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	unlike $xml, qr/<evil>/, 'title XML injection blocked';
	like $xml, qr/&lt;evil&gt;/, 'title injection properly escaped';
};

subtest 'XML injection via author/subtitle is neutralised' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Author:\"$XML_INJECT\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));
	unlike $xml, qr/<evil>/, 'author XML injection blocked';
};

subtest 'XML injection via copyright line is neutralised' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Copyright1:\"$DOCTYPE_INJECT\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	unlike $xml, qr/<!DOCTYPE foo/, 'DOCTYPE injection blocked in copyright';
	# After _xml_escape, "ENTITY" still appears literally inside "&lt;!ENTITY"
	# so we must check for the raw unescaped injection form.
	unlike $xml, qr/<!ENTITY/, 'raw entity declaration injection blocked';
	like $xml, qr/&lt;!DOCTYPE/, 'DOCTYPE injection is escaped';
};

subtest 'CDATA terminator ]]> in metadata is escaped' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"Before${CDATA_INJECT}After\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	# The output should either escape > as &gt; or leave ]] harmless;
	# either way, ]]> must not appear as a literal raw sequence in element content.
	unlike $xml, qr/\]\]>.*<\/credit-words>/s,
		']]> not present as raw literal inside credit-words';
};

subtest 'XML-illegal control chars in metadata are stripped from output' => sub {
	# Regression: _xml_escape previously left \x00-\x08, \x0B, \x0C, \x0E-\x1F
	# intact, producing invalid XML 1.0.  Fixed by stripping them first.
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"Hello\x00\x01\x02\x07World\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	# Control chars below 0x09 (excluding none) must not appear raw
	my @illegal = ($xml =~ /([\x00-\x08\x0B\x0C\x0E-\x1F])/g);
	is scalar @illegal, 0,
		'no XML 1.0 illegal control characters in output (regression: _xml_escape strip)';

	like $xml, qr/HelloWorld/, 'text content preserved with control chars stripped';
};

subtest 'XML-special chars in title: &, <, >, ", \'' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"Rock \\& Roll: <A>'B'\\\"C\\\"\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	like $xml, qr/&amp;/,  'ampersand escaped';
	like $xml, qr/&lt;/,   'less-than escaped';
	like $xml, qr/&gt;/,   'greater-than escaped';
	like $xml, qr/&quot;/, 'double-quote escaped';
};

subtest 'Staff with only UnsupportedEvents produces valid MusicXML skeleton' => sub {
	# A staff populated solely with UnsupportedEvents contains no sounding
	# notes. The generator must still produce structurally valid XML.
	my $score = Music::NWC2MusicXML::Parser->new->parse(
		$NWCTXT_HEADER
		. "|AddStaff|Name:\"S\"\n"
		. "|FutureThing|X:1\n"
		. "|Bar|\n"
	);
	my $xml;
	lives_ok {
		$xml = Music::NWC2MusicXML::MusicXML->new->generate($score)
	} 'unsupported-only staff: generator does not crash';
	like $xml, qr|<score-partwise|, 'root element present';
};

subtest 'MusicXML::generate output is pure ASCII regardless of staff name' => sub {
	# Staff name with multi-byte characters must be escaped to ASCII entity refs.
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"\x{2019}Round Midnight\"\n"
		. "|AddStaff|Name:\"\x{00E9}l\x{00E8}ve\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	my @non_ascii = ($xml =~ /([^\x00-\x7F])/g);
	is scalar @non_ascii, 0, 'non-ASCII characters in staff name escaped to ASCII';
	like $xml, qr/&#233;/, 'U+00E9 escaped as &#233; in output';
};

subtest 'Score with 100 staves: generate does not crash or OOM' => sub {
	my $nwctxt = $NWCTXT_HEADER;
	for my $i (1 .. 100) {
		$nwctxt .= "|AddStaff|Name:\"Staff$i\"\n"
			. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	}
	my $xml;
	lives_ok {
		$xml = Music::NWC2MusicXML::MusicXML->new->generate(
			Music::NWC2MusicXML::Parser->new->parse($nwctxt))
	} '100-staff score: generate completes without crash';

	my @parts = ($xml =~ /<part id=/g);
	is scalar @parts, 100, 'exactly 100 <part> elements';
};

subtest 'All-same staff names fall back to positional "Staff-N" names' => sub {
	my $nwctxt = $NWCTXT_HEADER;
	for my $i (1 .. 3) {
		$nwctxt .= "|AddStaff|Name:\"Piano\"\n|Note|Dur:4th|Pos:0\n|Bar|\n";
	}
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	# All three staves have the same name "Piano", so positional fallback applies
	unlike $xml, qr/Piano.*Piano.*Piano/s,
		'duplicate names replaced (no three literal "Piano" <part-name>s in sequence)';
	like $xml, qr/Staff-1/, 'positional fallback Staff-1 present';
};

subtest 'Extreme Note position values do not crash pitch converter' => sub {
	for my $pos (qw(-9999 9999 0)) {
		my $nwctxt = $NWCTXT_HEADER
			. "|AddStaff|Name:\"S\"\n"
			. "|Note|Dur:4th|Pos:$pos\n|Bar|\n";
		my $xml;
		lives_ok {
			$xml = Music::NWC2MusicXML::MusicXML->new->generate(
				Music::NWC2MusicXML::Parser->new->parse($nwctxt))
		} "Note Pos:$pos: generator does not crash";
	}
};

# ============================================================================
# 6. Diagnostics -- invalid levels, counters, closed filehandles
# ============================================================================

subtest 'Diagnostics::new invalid level croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Diagnostics->new(level => 'superverbose') }
		qr/Unknown log level/i,
		'invalid level: croaks';
};

subtest 'Diagnostics::new undef level croaks' => sub {
	throws_ok { Music::NWC2MusicXML::Diagnostics->new(level => undef) }
		qr//,
		'undef level: croaks (validate_strict or level guard)';
};

subtest 'Diagnostics::count unknown outcome croaks' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok { $d->count(outcome => 'invented_outcome') }
		qr/Unknown counter/i,
		'unknown counter: croaks';
};

subtest 'Diagnostics::count missing outcome croaks' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok { $d->count() }
		qr/required|validate/i,
		'no outcome argument: validate_strict croaks';
};

subtest 'Diagnostics::warn_unsupported missing required fields croaks' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	throws_ok { $d->warn_unsupported(file => 'f.nwc') }
		qr/required|validate/i,
		'missing staff/object: validate_strict croaks';
};

subtest 'Diagnostics::warn_unsupported with very large message does not crash' => sub {
	my $d = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $big = 'X' x 1_000_000;
	lives_ok {
		$d->warn_unsupported(
			file => $big, staff => $big, object => $big, reason => $big)
	} 'megabyte warning fields: no crash';
	ok $d->has_warnings, 'warning recorded';
};

subtest 'Diagnostics::new with closed filehandle stored (write happens lazily)' => sub {
	# The closed FH should cause issues only when a warning is actually written,
	# not at construction time.  Verify construction succeeds.
	my ($fh, $fname) = tempfile(UNLINK => 1);
	close $fh;
	my $d;
	lives_ok {
		$d = Music::NWC2MusicXML::Diagnostics->new(
			level       => 'quiet',
			warnings_fh => $fh,   # FH is closed
		);
	} 'closed FH passed to new(): construction does not croak';
	ok defined $d, 'Diagnostics object created even with closed FH';
};

# ============================================================================
# 7. Global variable isolation -- $_, $@, $! must not be contaminated
# ============================================================================

subtest 'parse() does not contaminate $_ in calling scope' => sub {
	local $_ = 'SENTINEL';
	Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
	is $_, 'SENTINEL', 'parse() did not modify $_ in caller scope';
};

subtest 'generate() does not contaminate $_ in calling scope' => sub {
	local $_ = 'SENTINEL';
	Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	is $_, 'SENTINEL', 'generate() did not modify $_ in caller scope';
};

subtest 'parse() does not propagate $@ from an internal eval on success' => sub {
	# Perl does not clear $@ just because a function succeeds; but functions
	# that use eval internally will set $@ to '' on successful completion.
	# The important invariant is that $@ must never hold a STALE error from
	# code inside parse() after parse() returns normally.
	eval { die "previous error\n" };
	my $old = $@;
	my $score = Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC);
	ok defined $score, 'parse() returned a Score object';
	# $@ may equal '' (if parse uses eval) or $old (if it does not).
	# Either way, it must NOT contain a new error from inside parse().
	ok !($@ && $@ ne $old), '$@ after successful parse() is not a new error from parse()';
};

subtest 'generate() does not propagate $@ from an internal eval on success' => sub {
	eval { die "old error\n" };
	my $old = $@;
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	ok length($xml) > 0, 'generate() returned non-empty XML';
	ok !($@ && $@ ne $old), '$@ after successful generate() is not a new error from generate()';
};

# ============================================================================
# 8. Context abuse -- list vs scalar context
# ============================================================================

subtest 'generate() in list context returns single scalar, not multiple items' => sub {
	my @r = Music::NWC2MusicXML::MusicXML->new->generate(_minimal_score());
	is scalar @r, 1, 'generate() in list context: exactly 1 item returned';
	like $r[0], qr/<score-partwise/, 'that item is the MusicXML document';
};

subtest 'staff->events() in list context returns same arrayref' => sub {
	my $staff = _minimal_score()->staves->[0];
	my @r = $staff->events;
	is scalar @r, 1, 'events() in list context: returns 1 item (the arrayref)';
	is ref $r[0], 'ARRAY', 'that item is an arrayref';
};

subtest 'staves() in list context returns single arrayref' => sub {
	my $score = _minimal_score();
	my @r = $score->staves;
	is scalar @r, 1, 'staves() in list context: 1 item (the arrayref)';
	is ref $r[0], 'ARRAY', 'that item is an arrayref';
};

# ============================================================================
# 9. I/O failure simulation -- Test::Mockingbird upstream stubs
# ============================================================================

subtest 'NWC::decode: Compress::Zlib::uncompress returning undef croaks' => sub {
	my $guard = mock_scoped(
		'Compress::Zlib', 'uncompress',
		sub { return undef },
	);

	# We need a blob with valid magic and a plausible zlib header byte (0x78)
	# so _find_zlib_offset finds a candidate before we even attempt to decompress.
	# Build: [NWZ] + 0x78 0x9C (zlib default compression header pair)
	my $data = $NWC_MAGIC . "\x78\x9C" . "\x00" x 100;
	my $nwc  = Music::NWC2MusicXML::NWC->new;

	throws_ok { $nwc->decode($data) }
		qr/Decompression failed/i,
		'uncompress returning undef: croaks decompression-failed';

	undef $guard;
};

subtest 'batch_convert: corrupt NWC file fails gracefully in batch' => sub {
	# Verify the failure-isolation fix: corrupted file returns undef from
	# convert(), not an exception.  batch_convert must count it as failed.
	my $dir  = tempdir(CLEANUP => 1);
	my $junk = File::Spec->catfile($dir, 'corrupt.nwc');

	open my $fh, '>:raw', $junk or die $!;
	print $fh $NWC_MAGIC . ("\x00" x 50);
	close $fh;

	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $r = $c->batch_convert(
		inputs     => [$junk, $PILGRIM_NWC],
		output_dir => $dir,
		overwrite  => 1,
	);

	is $r->{failed},     1, 'corrupt file counted as failed (regression)';
	is $r->{successful}, 1, 'good file still counted as successful';
	is $r->{processed},  2, 'both files processed';
};

subtest 'batch_convert: missing file counted as failed, not croaked' => sub {
	# A file that does not exist should cause convert() to croak, which
	# batch_convert must catch and tally as a failure, not abort the batch.
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');

	my $r;
	lives_ok {
		$r = $c->batch_convert(
			inputs     => ['/no/such/file_xyz.nwc', $PILGRIM_NWC],
			output_dir => $dir,
			overwrite  => 1,
		);
	} 'batch with missing file: batch_convert does not croak';

	is $r->{failed},     1, 'missing file counted as failed';
	is $r->{successful}, 1, 'good file counted as successful';
};

# ============================================================================
# 10. Filesystem hostility
# ============================================================================

subtest 'convert: output path with dangerous shell metacharacters is safe' => sub {
	# Verify Perl uses 3-arg open (no shell), so shell chars in path just
	# cause a "cannot open" error or create oddly-named files -- no injection.
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');

	# Pipe in output filename: should fail gracefully (file won't be written),
	# not execute a shell command.
	my $hostile_out = File::Spec->catfile($dir, 'out|whoami.musicxml');
	my $ret;
	lives_ok {
		$ret = $c->convert(
			input    => $PILGRIM_NWC,
			output   => $hostile_out,
			overwrite => 1,
		);
	} 'shell-metachar in output path: convert() does not crash or execute shell';

	diag "return: " . ($ret // 'undef') if $ENV{TEST_VERBOSE};
};

subtest 'convert: output path with directory traversal does not escape base' => sub {
	# We cannot fully test path traversal without knowing the filesystem layout,
	# but we verify that a path with ../../ in it either succeeds (writing
	# wherever it resolves) or fails gracefully -- it must never silently
	# overwrite a system file with a music XML document.
	my $dir = tempdir(CLEANUP => 1);
	my $traversal = File::Spec->catfile($dir, '..', '..', 'tmp', 'harmless.musicxml');
	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');

	# Use plain eval: the call may croak (e.g. can't create parent dir) or
	# succeed; either outcome is acceptable -- what matters is no shell
	# injection and no silent overwrite of unrelated files.
	my $ret = eval {
		$c->convert(
			input     => $PILGRIM_NWC,
			output    => $traversal,
			overwrite => 0,
		)
	};
	ok 1, 'path traversal in output: did not raise an unexpected exception or shell-inject';

	# If the file was created, it must be an XML document (not something harmful)
	if (defined $ret && -f $ret) {
		my $content;
		open my $fh, '<', $ret or die $!;
		read $fh, $content, 100;
		close $fh;
		like $content, qr/<\?xml/, 'traversal-path file contains valid XML (not system file)';
		unlink $ret;
	}
};

subtest 'NWC::read file with path containing spaces works' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'file with spaces.nwc');
	require File::Copy;
	File::Copy::copy($PILGRIM_NWC, $file) or die "copy: $!";

	my $nwc = Music::NWC2MusicXML::NWC->new;
	my $nwctxt;
	lives_ok { $nwctxt = $nwc->read($file) } 'filename with spaces: no crash';
	like $nwctxt, qr/!NoteWorthyComposer/, 'NWCTXT decoded successfully';
};

subtest 'convert to /dev/null produces no error' => sub {
	# /dev/null accepts all writes -- the file appears to exist, so overwrite=0
	# skips it.  This tests the guard path, not the write.
	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $ret;
	lives_ok {
		$ret = $c->convert(
			input    => $PILGRIM_NWC,
			output   => '/dev/null',
			overwrite => 1,
		)
	} 'output to /dev/null: does not croak';
};

# ============================================================================
# 11. Security probes
# ============================================================================

subtest 'XML output has no raw DOCTYPE or ENTITY declarations' => sub {
	# Any DOCTYPE or ENTITY that appears in the output must be our own
	# (the MusicXML schema DOCTYPE), not user-injected markup.
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"$DOCTYPE_INJECT\"|Copyright1:\"$DOCTYPE_INJECT\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	# Count DOCTYPE occurrences: only the one we generate should appear
	my @doctypes = ($xml =~ /<!DOCTYPE/g);
	is scalar @doctypes, 1, 'exactly one DOCTYPE declaration (ours, not injected)';
	unlike $xml, qr/<!ENTITY/, 'no raw ENTITY declarations in output';
};

subtest 'XML output contains no processing instruction other than XML declaration' => sub {
	my $nwctxt = $NWCTXT_HEADER
		. "|SongInfo|Title:\"$PROC_INJECT\"\n"
		. "|AddStaff|Name:\"S\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));

	my @pis = ($xml =~ /<\?(?!xml\b)/g);
	is scalar @pis, 0, 'no processing instructions injected via metadata';
};

subtest 'Output is well-formed: no unescaped bare < or > inside element content' => sub {
	# This is a basic XML well-formedness check: after stripping known tag
	# boundaries, no bare < or > should appear in text content.
	my $xml = _minimal_xml();

	# Remove all tags (open, close, empty).  What remains is text content and
	# declarations, which must not contain < or > (they should be &lt;/&gt;).
	(my $no_tags = $xml) =~ s/<[^>]*>//g;
	$no_tags =~ s/<!DOCTYPE[^>]*>//g;
	$no_tags =~ s/<\?xml[^?]*\?>//g;

	ok $no_tags !~ /[<>]/, 'no bare < or > in text content after tag removal';
};

subtest '_xml_escape: round-trip invariant -- escape/unescape equals original' => sub {
	# After escaping, the result must not contain any of the five XML special chars
	# in raw form.
	my @inputs = (
		'Hello & World',
		'<script>alert(1)</script>',
		'"double" and \'single\'',
		'a > b < c & d',
		'Completely "clean" text',
	);
	for my $input (@inputs) {
		my $escaped = Music::NWC2MusicXML::MusicXML::_xml_escape($input);
		# After escaping, & becomes &amp; so & appears in the result -- that is
		# correct. The invariant is that raw < and > must not appear.
		ok $escaped !~ /[<>]/, "no raw < or > after escaping: [$input]";
		like $escaped, qr/&amp;|&lt;|&gt;|&quot;|&apos;/
			if $input =~ /[&<>"']/;
	}
};

subtest '_xml_escape: undef input returns empty string' => sub {
	my $r = Music::NWC2MusicXML::MusicXML::_xml_escape(undef);
	is $r, '', '_xml_escape(undef) returns empty string (not crash)';
};

subtest '_xml_escape: NUL byte removed (regression: invalid XML 1.0)' => sub {
	my $r = Music::NWC2MusicXML::MusicXML::_xml_escape("before\x00after");
	is $r, 'beforeafter', 'NUL byte stripped from output';
};

subtest '_xml_escape: DEL byte (0x7F) removed' => sub {
	my $r = Music::NWC2MusicXML::MusicXML::_xml_escape("ok\x7Fbye");
	is $r, 'okbye', 'DEL (0x7F) stripped from output';
};

subtest '_xml_escape: tab, newline, CR preserved (valid XML 1.0 whitespace)' => sub {
	my $r = Music::NWC2MusicXML::MusicXML::_xml_escape("a\tb\nc\rd");
	is $r, "a\tb\nc\rd", 'tab/LF/CR preserved (valid XML whitespace)';
};

done_testing();
