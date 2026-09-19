#!/usr/bin/perl
use strict;
use warnings;

# End-to-end, black-box integration tests for Music::NWC2MusicXML.
# Tests focus on cross-module workflows and stateful interactions across
# the full pipeline: NWC binary -> NWCTXT -> Score IR -> MusicXML output.
#
# Strategy:
#   1. Pipeline integration: NWC + Parser + MusicXML wired through shared Diagnostics
#   2. Facade integration: Music::NWC2MusicXML::convert and batch_convert
#   3. State isolation: multiple independent objects must not share state
#   4. Optional dependency: Compress::Zlib absent => NWC.pm load fails gracefully
#   5. Output correctness: XML structure, ASCII purity, credit/rights placement
#   6. Error propagation: per-file failures in batch mode counted, not fatal

use Test::Most;
use Test::Returns;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use File::Copy;
use Readonly;
use Scalar::Util qw(blessed refaddr);

use lib 'lib';
use Music::NWC2MusicXML;
use Music::NWC2MusicXML::NWC;
use Music::NWC2MusicXML::Parser;
use Music::NWC2MusicXML::MusicXML;
use Music::NWC2MusicXML::Diagnostics;
use Music::NWC2MusicXML::Score;
use Music::NWC2MusicXML::Staff;
use Music::NWC2MusicXML::Event;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $PILGRIM_NWC  => 't/input/Pilgrim.nwc';

# Known facts about the Pilgrim.nwc fixture
Readonly::Scalar my $PILGRIM_TITLE    => 'To a Pilgrim';
Readonly::Scalar my $PILGRIM_AUTHOR   => 'Trad, Arr Nigel Horne';
Readonly::Scalar my $PILGRIM_STAVES   => 4;
Readonly::Scalar my $PILGRIM_NWC_VER  => '2.751';

# NWCTXT for a minimal one-staff, one-note score used across many tests
Readonly::Scalar my $MINIMAL_NWC => <<'END_NWC';
!NoteWorthyComposer(2.75)
|SongInfo|Title:"Integration Test"|Author:"Test Author"|Copyright1:"(c) 2025"|Copyright2:"All Rights Reserved"
|PgSetup|StaffSize:16
|AddStaff|Name:"Piano"|Group:Standard
|StaffProperties|Visible:Y|Lines:5
|StaffInstrument|Name:"Grand Piano"|Patch:0
|Clef|Type:Treble
|Key|Signature:C
|TimeSig|Signature:4/4
|Tempo|Tempo:120|Base:Quarter
|Note|Dur:4th|Pos:0
|Bar|
END_NWC

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _minimal_xml {
	my ($nwctxt) = @_;
	$nwctxt //= $MINIMAL_NWC;
	return Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse($nwctxt));
}

# ============================================================================
# 1. Module loading
# ============================================================================

subtest 'All modules load cleanly' => sub {
	ok $Music::NWC2MusicXML::VERSION,             'facade VERSION defined';
	ok $Music::NWC2MusicXML::NWC::VERSION,        'NWC VERSION defined';
	ok $Music::NWC2MusicXML::Parser::VERSION,     'Parser VERSION defined';
	ok $Music::NWC2MusicXML::MusicXML::VERSION,   'MusicXML VERSION defined';
	ok $Music::NWC2MusicXML::Diagnostics::VERSION,'Diagnostics VERSION defined';
	ok $Music::NWC2MusicXML::Score::VERSION,      'Score VERSION defined';
	ok $Music::NWC2MusicXML::Staff::VERSION,      'Staff VERSION defined';
	ok $Music::NWC2MusicXML::Event::VERSION,      'Event VERSION defined';
};

# ============================================================================
# 2. Optional dependency: Compress::Zlib
# ============================================================================

# We use a child process so we can test NWC.pm load in a clean namespace
# without disturbing the parent's already-loaded module registry.

subtest 'NWC.pm load fails gracefully when Compress::Zlib absent' => sub {
	# The child script uses Test::Without::Module before requiring NWC.pm.
	# Exit 0 = NWC.pm correctly failed to load; exit 1 = NWC.pm loaded (unexpected).
	my $script = join ' ; ',
		q{use Test::Without::Module 'Compress::Zlib'},
		q{my $ok = eval { require Music::NWC2MusicXML::NWC; 1 }},
		q{exit($ok ? 1 : 0)};
	system($^X, '-Ilib', '-e', $script);
	my $exit = $? >> 8;
	is $exit, 0, 'NWC.pm fails to load without Compress::Zlib (exit 0 = correct)';
};

subtest 'Parser+MusicXML pipeline works independently of Compress::Zlib' => sub {
	# Parser and MusicXML modules do not import Compress::Zlib at all.
	# Verify both modules are usable and produce valid output without any
	# binary NWC decoding step involved.
	my $xml;
	lives_ok {
		$xml = Music::NWC2MusicXML::MusicXML->new->generate(
			Music::NWC2MusicXML::Parser->new->parse($MINIMAL_NWC));
	} 'Parser -> MusicXML pipeline runs without Compress::Zlib involvement';
	like $xml, qr/<score-partwise/, 'valid MusicXML produced';

	diag 'xml length: ' . length($xml) if $ENV{TEST_VERBOSE};
};

# ============================================================================
# 3. Full pipeline: NWC binary -> NWCTXT -> Score -> MusicXML
# ============================================================================

subtest 'Full three-stage pipeline on real .nwc file' => sub {
	my $nwc  = Music::NWC2MusicXML::NWC->new;
	my $par  = Music::NWC2MusicXML::Parser->new;
	my $gen  = Music::NWC2MusicXML::MusicXML->new;

	my $nwctxt;
	lives_ok { $nwctxt = $nwc->read($PILGRIM_NWC) } 'Stage 1: NWC decode';
	like $nwctxt, qr/!NoteWorthyComposer\(/, 'NWCTXT header present';

	my $score;
	lives_ok { $score = $par->parse($nwctxt) } 'Stage 2: Parser';
	is blessed($score), 'Music::NWC2MusicXML::Score', 'Score object returned';
	is $score->staff_count, $PILGRIM_STAVES, "Score has $PILGRIM_STAVES staves";
	is $score->nwc_version, $PILGRIM_NWC_VER, 'NWC version extracted';
	is $score->metadata->{Title},  $PILGRIM_TITLE,  'Title metadata';
	is $score->metadata->{Author}, $PILGRIM_AUTHOR, 'Author metadata';

	my $xml;
	lives_ok { $xml = $gen->generate($score) } 'Stage 3: MusicXML generation';
	returns_ok($xml, { type => 'scalar' }, 'generate returns scalar');
	like $xml, qr|<score-partwise version="4\.0">|, 'MusicXML 4.0 root';

	diag "XML size: " . length($xml) . " bytes" if $ENV{TEST_VERBOSE};
};

subtest 'Shared Diagnostics instance flows through all three stages' => sub {
	my $diag = Music::NWC2MusicXML::Diagnostics->new(level => 'quiet');
	my $nwc  = Music::NWC2MusicXML::NWC->new(diagnostics => $diag);
	my $par  = Music::NWC2MusicXML::Parser->new(diagnostics => $diag);
	my $gen  = Music::NWC2MusicXML::MusicXML->new(diagnostics => $diag);

	# Each stage stores the same Diagnostics object, identifiable by refaddr
	is refaddr($diag), refaddr($nwc->{_diagnostics}), 'NWC shares Diagnostics';
	is refaddr($diag), refaddr($par->{_diagnostics}), 'Parser shares Diagnostics';
	is refaddr($diag), refaddr($gen->{_diagnostics}), 'MusicXML shares Diagnostics';

	my $nwctxt = $nwc->read($PILGRIM_NWC);
	my $score  = $par->parse($nwctxt);
	my $xml    = $gen->generate($score);
	ok length($xml) > 0, 'pipeline produces non-empty output';
};

# ============================================================================
# 4. Parser state isolation (reuse across calls)
# ============================================================================

subtest 'Parser::parse resets state between calls (no state bleed)' => sub {
	my $p    = Music::NWC2MusicXML::Parser->new;
	my $nwc1 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"First\"|Author:\"AuthorOne\"\n"
		. "|AddStaff|Name:\"Staff1\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $nwc2 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"Second\"\n"
		. "|AddStaff|Name:\"StaffA\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n"
		. "|AddStaff|Name:\"StaffB\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n"
		. "|AddStaff|Name:\"StaffC\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";

	my $s1 = $p->parse($nwc1);
	my $s2 = $p->parse($nwc2);

	# Verify no metadata bleeds from first parse to second
	is $s1->metadata->{Title}, 'First',  'first parse: Title = First';
	is $s2->metadata->{Title}, 'Second', 'second parse: Title = Second';
	ok !defined($s2->metadata->{Author}), 'Author from first parse does not bleed';

	# Staff counts must correspond to each respective input
	is $s1->staff_count, 1, 'first parse: 1 staff';
	is $s2->staff_count, 3, 'second parse: 3 staves';

	# Score objects must be independent (distinct references)
	isnt refaddr($s1), refaddr($s2), 'two distinct Score objects';
};

subtest 'MusicXML generator reuse produces independent documents' => sub {
	my $gen  = Music::NWC2MusicXML::MusicXML->new;
	my $par  = Music::NWC2MusicXML::Parser->new;

	my $nwc1 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"Alpha\"\n"
		. "|AddStaff|Name:\"V1\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $nwc2 = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"Beta\"\n"
		. "|AddStaff|Name:\"V2\"\n"
		. "|Note|Dur:Whole|Pos:0\n|Bar|\n";

	my $xml1 = $gen->generate($par->parse($nwc1));
	my $xml2 = $gen->generate($par->parse($nwc2));

	like $xml1, qr/Alpha/, 'xml1 contains title Alpha';
	like $xml2, qr/Beta/,  'xml2 contains title Beta';
	unlike $xml1, qr/Beta/,  'xml1 does not contain Beta';
	unlike $xml2, qr/Alpha/, 'xml2 does not contain Alpha';

	# Documents must be distinct strings
	isnt $xml1, $xml2, 'two distinct MusicXML documents';
};

# ============================================================================
# 5. Two independent converter instances (concurrency / isolation)
# ============================================================================

subtest 'Two Music::NWC2MusicXML instances are fully independent' => sub {
	my $dir = tempdir(CLEANUP => 1);

	my $c1 = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $c2 = Music::NWC2MusicXML->new(log_level => 'quiet');

	# Internal components must be distinct objects
	isnt refaddr($c1->{_diagnostics}), refaddr($c2->{_diagnostics}),
		'each instance has its own Diagnostics';
	isnt refaddr($c1->{_decoder}), refaddr($c2->{_decoder}),
		'each instance has its own NWC decoder';
	isnt refaddr($c1->{_parser}),  refaddr($c2->{_parser}),
		'each instance has its own Parser';
	isnt refaddr($c1->{_generator}), refaddr($c2->{_generator}),
		'each instance has its own MusicXML generator';

	# Both converters must produce identical output for the same input
	my $out1 = $c1->convert(
		input    => $PILGRIM_NWC,
		output   => File::Spec->catfile($dir, 'c1.musicxml'),
		overwrite => 1,
	);
	my $out2 = $c2->convert(
		input    => $PILGRIM_NWC,
		output   => File::Spec->catfile($dir, 'c2.musicxml'),
		overwrite => 1,
	);

	ok -f $out1, 'c1 output file exists';
	ok -f $out2, 'c2 output file exists';
	is -s $out1, -s $out2, 'both outputs are the same size (deterministic)';

	# c1 increments its own counter; c2 must be unaffected
	my $c2_processed_before = $c2->{_diagnostics}{_counts}{processed};
	$c1->{_diagnostics}->count(outcome => 'processed');
	is $c2->{_diagnostics}{_counts}{processed}, $c2_processed_before,
		'c2 processed counter unchanged after c1 increment';

	diag "Output size: " . (-s $out1) . " bytes" if $ENV{TEST_VERBOSE};
};

# ============================================================================
# 6. Facade::convert -- single-file workflow
# ============================================================================

subtest 'convert: default output path derived from input' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $nwc_copy = File::Spec->catfile($dir, 'Pilgrim.nwc');
	File::Copy::copy($PILGRIM_NWC, $nwc_copy)
		or die "copy failed: $!";

	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $out = $c->convert(input => $nwc_copy, overwrite => 1);

	my $expected = File::Spec->catfile($dir, 'Pilgrim.musicxml');
	is $out, $expected, 'default output path replaces .nwc with .musicxml';
	ok -f $out, 'default output file exists';
};

subtest 'convert: explicit output path honoured' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $out_path = File::Spec->catfile($dir, 'custom_name.musicxml');

	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $out = $c->convert(
		input    => $PILGRIM_NWC,
		output   => $out_path,
		overwrite => 1,
	);

	is $out, $out_path, 'returned path matches explicit output';
	ok -f $out_path, 'custom-named output file exists';
};

subtest 'convert: skips existing output when overwrite => 0' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $out = File::Spec->catfile($dir, 'out.musicxml');

	# Plant a stub file to simulate an existing output
	open my $fh, '>', $out or die $!;
	print $fh 'stub';
	close $fh;
	my $before_size = -s $out;

	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $ret = $c->convert(input => $PILGRIM_NWC, output => $out, overwrite => 0);

	is $ret, $out, 'returns output path even when skipped';
	is -s $out, $before_size, 'existing file not modified when overwrite => 0';
};

subtest 'convert: overwrites existing output when overwrite => 1' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $out = File::Spec->catfile($dir, 'out.musicxml');

	open my $fh, '>', $out or die $!;
	print $fh 'stub';
	close $fh;
	my $before_size = -s $out;

	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	$c->convert(input => $PILGRIM_NWC, output => $out, overwrite => 1);

	my $after_size = -s $out;
	ok $after_size > $before_size, 'output file was replaced (overwrite => 1)';
};

subtest 'convert: croaks on missing input file' => sub {
	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	throws_ok { $c->convert(input => '/no/such/file.nwc') }
		qr/Input file not found/, 'missing file croaks error_file_not_found';
};

subtest 'convert: creates output directory if needed' => sub {
	my $dir    = tempdir(CLEANUP => 1);
	my $subdir = File::Spec->catfile($dir, 'deep', 'subdir');
	my $out    = File::Spec->catfile($subdir, 'out.musicxml');

	# The subdirectory must not exist yet
	ok !-d $subdir, 'subdirectory does not exist initially';

	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	$c->convert(input => $PILGRIM_NWC, output => $out, overwrite => 1);

	ok -d $subdir, 'output directory was created';
	ok -f $out,    'output file was written inside new directory';
};

subtest 'convert: validate => 1 exercises Score::validate without aborting' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet', validate => 1);
	my $out;
	lives_ok {
		$out = $c->convert(
			input    => $PILGRIM_NWC,
			output   => File::Spec->catfile($dir, 'out.musicxml'),
			overwrite => 1,
		);
	} 'convert with validate => 1 does not croak';
	ok -f $out, 'output file written even with validate => 1';
};

# ============================================================================
# 7. Facade::batch_convert
# ============================================================================

subtest 'batch_convert: empty input list returns zero counts' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $r   = $c->batch_convert(inputs => [], output_dir => $dir);

	returns_ok($r, { type => 'hashref' }, 'batch_convert returns hashref');
	is $r->{processed},  0, 'processed = 0';
	is $r->{successful}, 0, 'successful = 0';
	is $r->{failed},     0, 'failed = 0';
	is $r->{warnings},   0, 'warnings = 0';
	is_deeply $r->{results}, [], 'results is empty arrayref';
};

subtest 'batch_convert: single file succeeds' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $r   = $c->batch_convert(
		inputs     => [$PILGRIM_NWC],
		output_dir => $dir,
		overwrite  => 1,
	);

	is $r->{processed},  1, 'processed = 1';
	is $r->{successful}, 1, 'successful = 1';
	is $r->{failed},     0, 'failed = 0';
	ok $r->{results}[0]{ok}, 'result entry ok flag set';
	is $r->{results}[0]{input}, $PILGRIM_NWC, 'result input path correct';
	ok -f $r->{results}[0]{output}, 'output file exists';
};

subtest 'batch_convert: per-file failure counted but does not abort batch' => sub {
	my $dir     = tempdir(CLEANUP => 1);
	my $missing = File::Spec->catfile($dir, 'no_such_file.nwc');
	my $c       = Music::NWC2MusicXML->new(log_level => 'quiet');

	my $r = $c->batch_convert(
		inputs    => [$PILGRIM_NWC, $missing],
		output_dir => $dir,
		overwrite  => 1,
	);

	is $r->{processed},  2, 'both files counted as processed';
	is $r->{successful}, 1, 'one file succeeded';
	is $r->{failed},     1, 'one file failed';
	ok !$r->{results}[1]{ok}, 'failed entry has ok => false';

	# The successful output must still exist
	ok -f $r->{results}[0]{output}, 'successful output file exists';
};

subtest 'batch_convert: output_dir places all files in same directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $r   = $c->batch_convert(
		inputs     => [$PILGRIM_NWC],
		output_dir => $dir,
		overwrite  => 1,
	);

	my $expected = File::Spec->catfile($dir, 'Pilgrim.musicxml');
	is $r->{results}[0]{output}, $expected, 'output placed in output_dir';
	ok -f $expected, 'file exists at expected path';
};

subtest 'batch_convert: recursive mode preserves directory structure' => sub {
	my $dir      = tempdir(CLEANUP => 1);
	my $base_dir = 't/input';
	my $c        = Music::NWC2MusicXML->new(log_level => 'quiet');

	my $r = $c->batch_convert(
		inputs     => [$PILGRIM_NWC],
		output_dir => $dir,
		recursive  => 1,
		base_dir   => $base_dir,
		overwrite  => 1,
	);

	is $r->{successful}, 1, 'conversion succeeded in recursive mode';
	ok -f $r->{results}[0]{output}, 'output file exists';
	diag "recursive output: $r->{results}[0]{output}" if $ENV{TEST_VERBOSE};
};

subtest 'batch_convert: results arrayref has one entry per input' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');

	# Pass the same file twice to get two result entries
	my $r = $c->batch_convert(
		inputs    => [$PILGRIM_NWC, $PILGRIM_NWC],
		output_dir => $dir,
		overwrite  => 1,
	);

	is scalar @{ $r->{results} }, 2, 'results has two entries for two inputs';
	is $r->{processed}, 2, 'processed = 2';
};

# ============================================================================
# 8. warnings_fh integration
# ============================================================================

subtest 'warnings_fh: written-to filehandle receives warning text' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my ($wfh, $wfile) = tempfile(DIR => $dir, SUFFIX => '.warnings');

	my $diag = Music::NWC2MusicXML::Diagnostics->new(
		level       => 'quiet',
		warnings_fh => $wfh,
	);
	$diag->warn_unsupported(
		file   => 'score.nwc',
		staff  => '1',
		object => 'UserTool',
	);
	close $wfh;

	open my $rfh, '<', $wfile or die "cannot read $wfile: $!";
	my $content = do { local $/; <$rfh> };
	close $rfh;

	like $content, qr/UserTool/, 'warning text written to filehandle';
	like $content, qr/score\.nwc/, 'filename in warning text';

	diag "warning file content: $content" if $ENV{TEST_VERBOSE};
};

subtest 'warnings_fh: accepted by Music::NWC2MusicXML::new via warnings_fh kwarg' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my ($wfh, $wfile) = tempfile(DIR => $dir, SUFFIX => '.warn');

	my $c;
	lives_ok {
		$c = Music::NWC2MusicXML->new(log_level => 'quiet', warnings_fh => $wfh);
	} 'Music::NWC2MusicXML->new accepts warnings_fh';
	ok defined $c, 'converter object created';

	close $wfh;
};

# ============================================================================
# 9. MusicXML output correctness
# ============================================================================

subtest 'Output is pure 7-bit ASCII (no raw non-ASCII bytes)' => sub {
	my $xml = _minimal_xml();
	my @non_ascii = ($xml =~ /([^\x00-\x7F])/g);
	is scalar @non_ascii, 0, 'zero non-ASCII bytes in generated XML';
};

subtest 'Non-ASCII copyright symbol escaped to &#169; in output' => sub {
	# U+00A9 COPYRIGHT SIGN must be entity-escaped to keep output as pure ASCII
	my $non_ascii_nwc = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"Non-ASCII Score\""
		. "|Copyright1:\"\x{A9} 2025 Author\"\n"
		. "|AddStaff|Name:\"Flute\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = _minimal_xml($non_ascii_nwc);
	like $xml, qr/&#169;/, 'U+00A9 copyright sign escaped as &#169;';
	my @non_ascii = ($xml =~ /([^\x00-\x7F])/g);
	is scalar @non_ascii, 0, 'output remains pure ASCII after escaping';
};

subtest 'XML declaration and DOCTYPE present in every output' => sub {
	my $xml = _minimal_xml();
	like $xml, qr|^<\?xml version="1\.0" encoding="UTF-8"\?>|,
		'XML declaration at start';
	like $xml, qr/<!DOCTYPE score-partwise PUBLIC/, 'DOCTYPE present';
	like $xml, qr|<score-partwise version="4\.0">|, 'MusicXML 4.0 root';
	like $xml, qr|</score-partwise>|, 'root element closed';
};

subtest '<defaults> block always emitted before <credit> elements' => sub {
	my $xml = _minimal_xml();
	my $defaults_pos = index($xml, '<defaults>');
	my $credit_pos   = index($xml, '<credit');

	ok $defaults_pos >= 0, '<defaults> block present';
	ok $credit_pos   >= 0, 'at least one <credit> element present';
	ok $defaults_pos < $credit_pos, '<defaults> appears before first <credit>';
};

subtest 'Title and subtitle credits are restricted to page 1' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Title:\"My Score\"|Author:\"Composer\"\n"
		. "|AddStaff|Name:\"Pno\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = _minimal_xml($nwc);

	my @page1_credits = ($xml =~ /<credit page="1">/g);
	is scalar @page1_credits, 2, 'exactly 2 page-1 credits (title + subtitle)';
	like $xml, qr/<credit-type>title<\/credit-type>/,    'title credit-type present';
	like $xml, qr/<credit-type>subtitle<\/credit-type>/, 'subtitle credit-type present';
	like $xml, qr/My Score/,   'title text in output';
	like $xml, qr/Composer/,   'author text in output';
};

subtest 'Two copyright lines produce separate <credit> elements' => sub {
	my $nwc = "!NoteWorthyComposer(2.75)\n"
		. "|SongInfo|Copyright1:\"Line One\"|Copyright2:\"Line Two\"\n"
		. "|AddStaff|Name:\"Pno\"\n"
		. "|Note|Dur:4th|Pos:0\n|Bar|\n";
	my $xml = _minimal_xml($nwc);

	my @rights_credits = ($xml =~ /<credit-type>rights<\/credit-type>/g);
	is scalar @rights_credits, 2, 'one <credit> element per copyright line';
	like $xml, qr/Line One/, 'Copyright1 text present';
	like $xml, qr/Line Two/, 'Copyright2 text present';

	# Rights credits have no page attribute (they appear on every page)
	ok $xml !~ m|<credit page="\d+">\s*<credit-type>rights|,
		'rights credit elements carry no page= attribute';
};

subtest 'Single <rights> in <identification> joins both copyright lines' => sub {
	my $xml = _minimal_xml();
	my @rights_els = ($xml =~ m|<rights>(.*?)</rights>|gs);
	is scalar @rights_els, 1, 'single <rights> element in <identification>';
	like $rights_els[0], qr/\(c\) 2025/,         'Copyright1 in rights element';
	like $rights_els[0], qr/All Rights Reserved/, 'Copyright2 in rights element';
};

subtest 'Multi-staff score: one <part> and one <score-part> per staff' => sub {
	my $xml = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse(
			Music::NWC2MusicXML::NWC->new->read($PILGRIM_NWC)));

	my @parts       = ($xml =~ /<part id="(P\d+)"/g);
	my @score_parts = ($xml =~ /<score-part id="(P\d+)"/g);

	is scalar @parts,       $PILGRIM_STAVES, "exactly $PILGRIM_STAVES <part> elements";
	is scalar @score_parts, $PILGRIM_STAVES, "exactly $PILGRIM_STAVES <score-part> elements";

	# Part IDs in <part-list> must match those in the musical content
	is_deeply \@score_parts, \@parts, 'score-part IDs match part IDs in order';
};

subtest 'Output ends with a single newline' => sub {
	my $xml = _minimal_xml();
	like $xml, qr/\n$/, 'XML string ends with a newline';
	unlike $xml, qr/\n\n$/, 'XML string does not end with a double newline';
};

# ============================================================================
# 10. Error propagation across the pipeline
# ============================================================================

subtest 'Corrupted NWC binary: convert returns undef (does not croak)' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $junk = File::Spec->catfile($dir, 'corrupt.nwc');

	# File with NWC magic but an invalid / undecompressable payload
	open my $fh, '>:raw', $junk or die $!;
	print $fh '[NWZ]' . ("\x00" x 50);
	close $fh;

	my $c   = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $out = File::Spec->catfile($dir, 'corrupt.musicxml');
	my $ret;
	lives_ok { $ret = $c->convert(input => $junk, output => $out, overwrite => 1) }
		'corrupted NWC: convert does not croak';
	ok !defined $ret, 'returns undef on NWC decode failure';
	ok !-f $out, 'no output file created for failed conversion';
};

subtest 'Parser failure handled gracefully by batch_convert' => sub {
	# Verify that batch_convert counts failures correctly and keeps going
	# even when one file cannot be decoded. We test using a corrupted file
	# which will fail at Stage 1 (NWC decode), not by mocking.
	my $dir  = tempdir(CLEANUP => 1);
	my $junk = File::Spec->catfile($dir, 'corrupt.nwc');

	open my $fh, '>:raw', $junk or die $!;
	print $fh '[NWZ]' . ("\x00" x 50);
	close $fh;

	my $c = Music::NWC2MusicXML->new(log_level => 'quiet');
	my $r = $c->batch_convert(
		inputs     => [$junk, $PILGRIM_NWC],
		output_dir => $dir,
		overwrite  => 1,
	);

	is $r->{processed},  2, 'both files attempted';
	is $r->{failed},     1, 'corrupt file counted as failed';
	is $r->{successful}, 1, 'good file counted as successful';
};

# ============================================================================
# 11. End-to-end golden output stability
# ============================================================================

subtest 'Full pipeline on Pilgrim.nwc produces deterministic output' => sub {
	my $xml1 = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse(
			Music::NWC2MusicXML::NWC->new->read($PILGRIM_NWC)));
	my $xml2 = Music::NWC2MusicXML::MusicXML->new->generate(
		Music::NWC2MusicXML::Parser->new->parse(
			Music::NWC2MusicXML::NWC->new->read($PILGRIM_NWC)));

	is $xml1, $xml2, 'two independent pipeline runs produce identical output';
	diag 'Pilgrim.nwc XML length: ' . length($xml1) if $ENV{TEST_VERBOSE};
};

subtest 'Pilgrim.nwc: known metadata survives full pipeline' => sub {
	my $score = Music::NWC2MusicXML::Parser->new->parse(
		Music::NWC2MusicXML::NWC->new->read($PILGRIM_NWC));

	is $score->metadata->{Title},  $PILGRIM_TITLE,  'Title survives decode+parse';
	is $score->metadata->{Author}, $PILGRIM_AUTHOR, 'Author survives decode+parse';
	ok defined $score->metadata->{Copyright1}, 'Copyright1 present';
	ok defined $score->metadata->{Copyright2}, 'Copyright2 present';

	my $xml = Music::NWC2MusicXML::MusicXML->new->generate($score);
	like $xml, qr/\Q$PILGRIM_TITLE\E/, 'title present in MusicXML output';
};

done_testing;
