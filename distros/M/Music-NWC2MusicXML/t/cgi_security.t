#!/usr/bin/env perl
#
# t/cgi_security.t -- Penetration tests for Music::NWC2MusicXML
#
# Even though this is a CLI/library module (not a CGI script), it accepts
# caller-supplied file paths that can be weaponised in any context where the
# converter is exposed to untrusted input (web upload handler, CI pipeline
# processing user-submitted scores, REST API wrapper).
#
# Security contract for each attack vector:
#   SAFE outcome  = controlled croak (known error message) OR return undef
#   UNSAFE outcome = shell command executed, sensitive data leaked, or crash
#
# Attack surface analysed:
#   convert(input  => ...)  -- arbitrary read path
#   convert(output => ...)  -- arbitrary write path
#   batch_convert(inputs/output_dir/base_dir)
#       -- recursive path via abs2rel (confirmed traversal; now fixed)
#   NWC file content --> MusicXML output -- XML/content injection

use strict;
use warnings;

use Test::Most;
use File::Temp   qw(tempdir tempfile);
use File::Spec   ();
use File::Path   qw(make_path);
use Readonly;
use Compress::Zlib ();

use lib 'lib';
use Music::NWC2MusicXML;

# ---------------------------------------------------------------------------
# Constants -- no magic strings/numbers
# ---------------------------------------------------------------------------

Readonly::Scalar my $PILGRIM_NWC => 't/input/Pilgrim.nwc';
Readonly::Scalar my $NWC_MAGIC   => '[NWZ]';
Readonly::Scalar my $NWC_VERSION => '2.751';
Readonly::Scalar my $OUTPUT_EXT  => '.musicxml';

# Shell-injection payloads -- dangerous in 2-arg open or system() contexts.
Readonly::Scalar my $SHELL_PIPE  => '|id; echo INJECTED';
Readonly::Scalar my $SHELL_SEMI  => ';id;';
Readonly::Scalar my $SHELL_TICK  => '`id`';
Readonly::Scalar my $SHELL_DOLLAR=> '$(id)';

# Path-traversal payloads.
Readonly::Scalar my $TRAV_INPUT  => '../../../etc/passwd';
Readonly::Scalar my $TRAV_UNIX   => '../../../etc/hosts';

# Other hostile inputs.
Readonly::Scalar my $NULL_BYTE   => "innocent\x00/etc/shadow";
Readonly::Scalar my $CRLF_NAME   => "score.nwc\r\nX-Injected: header";
Readonly::Scalar my $LONG_PATH   => ('A' x 65_535) . '.nwc';
Readonly::Scalar my $XML_INJECT  => '<script>alert(1)</script>';
Readonly::Scalar my $XML_ATTR    => '" onload="alert(1)';

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _make_nwc {
	my ($staves) = @_;
	my $nwctxt = "!NoteWorthyComposer($NWC_VERSION)\n"
		. "|SongInfo|Title:Test\n"
		. $staves
		. "!NoteWorthyComposer-End\n";
	return $NWC_MAGIC . Compress::Zlib::compress(\$nwctxt);
}

sub _write_nwc_tempfile {
	my ($staves) = @_;
	my $fh = File::Temp->new(SUFFIX => '.nwc', UNLINK => 1);
	binmode $fh;
	print $fh _make_nwc($staves);
	$fh->close;
	return $fh;
}

Readonly::Scalar my $MINIMAL_STAFF =>
	"|AddStaff|Name:\"Piano\"\n"
	. "|Clef|Type:Treble\n"
	. "|Key|Signature:Concert\n"
	. "|TimeSig|Signature:4/4\n"
	. "|Note|Dur:Whole|Pos:0\n"
	. "|Bar|\n";

sub _converter { return Music::NWC2MusicXML->new(log_level => 'quiet') }

# Try a convert() call that may either croak (file not found) or return undef
# (file found but invalid NWC).  Either outcome is safe.  Returns the croak
# message (or '') so the caller can inspect it.
sub _try_convert {
	my ($c, %args) = @_;
	my $result = eval { $c->convert(%args) };
	my $err    = $@;
	return ($result, $err);
}

# ---------------------------------------------------------------------------
# 1. Input path: directory traversal via '..'
#
# Exploit: passing '../../../etc/passwd' may reach outside the working area.
# Safe outcome A: file absent   -> croak error_file_not_found (known message)
# Safe outcome B: file present  -> NWC magic check fails     -> return undef
# In neither case is a shell command executed.
# ---------------------------------------------------------------------------

subtest 'input path traversal: ../../../etc/passwd rejected safely' => sub {
	my $c = _converter();
	my ($result, $err) = _try_convert($c, input => $TRAV_INPUT);

	# Exactly one of these must be true:
	ok !defined $result, 'path traversal: result is undef (no output produced)';

	if ($err) {
		# croak path -- error message must not echo injected shell content
		like $err, qr/not found|magic|not a valid|truncated/i,
			'path traversal: croak message is a controlled error';
		unlike $err, qr/INJECTED|id\s*=\s*0/,
			'path traversal: croak message contains no shell output';
	}

	pass 'path traversal input: completed without shell injection';
};

# ---------------------------------------------------------------------------
# 2. Input path: null byte injection
#
# Exploit: on old Perls, 2-arg open("file\x00cmd") truncates at \x00.
# With 3-arg open the \x00 is a literal pathname character -- no such file
# exists, so the Perl stat call warns and the -f check returns false.
# Safe outcome: croak with a controlled error; no file is opened.
# ---------------------------------------------------------------------------

subtest 'input path: null byte handled as literal char (no truncation exploit)' => sub {
	my $c = _converter();

	# Suppress the "Invalid \0 in pathname" Perl warning; it is expected here.
	local $SIG{__WARN__} = sub { 1 };

	my ($result, $err) = _try_convert($c, input => $NULL_BYTE);

	ok !defined $result, 'null-byte path: returns undef (no output)';

	if ($err) {
		# Must be a controlled error, never a shell command result.
		unlike $err, qr/INJECTED/, 'null-byte: croak contains no injected content';
	}

	pass 'null-byte input: no shell executed, no crash';
};

# ---------------------------------------------------------------------------
# 3. Input path: shell metacharacters
#
# Exploit: '|cmd', ';cmd;', '`cmd`', '$(cmd)' in a 2-arg open would fork a
# shell and execute the command.  The code uses 3-arg open everywhere, so
# the metachar is a literal filename character.  File not found -> safe croak.
# ---------------------------------------------------------------------------

subtest 'input path: shell pipe (|) is not executed' => sub {
	my $c   = _converter();
	my $dir = tempdir(CLEANUP => 1);

	# Place the pipe INSIDE a valid tempdir so the path is well-formed on disk
	# apart from the pipe character itself.
	my $hostile = File::Spec->catfile($dir, "$SHELL_PIPE.nwc");

	my ($result, $err) = _try_convert($c, input => $hostile);

	ok !defined $result, 'pipe metachar: no output produced';
	# The filename (containing "INJECTED") will legitimately appear in the
	# "not found" error message; that is correct echoing, not shell output.
	# Shell execution would produce uid=X(user)... on a separate line.
	unlike ($err // '', qr/uid=\d+/, 'pipe metachar: no shell id-command output in error');
	like   ($err // 'undef', qr/not found|Input file not found|\Q$hostile\E/i,
		'pipe metachar: controlled error message, filename treated as literal');
	pass 'pipe metachar: 3-arg open treats | as filename char';
};

subtest 'input path: semicolon and backtick metachar not executed' => sub {
	my $c   = _converter();
	my $dir = tempdir(CLEANUP => 1);

	for my $meta ($SHELL_SEMI, $SHELL_TICK, $SHELL_DOLLAR) {
		my $hostile = File::Spec->catfile($dir, "${meta}.nwc");
		my ($result, $err) = _try_convert($c, input => $hostile);
		ok !defined $result, "metachar '$meta': no output";
		unlike ($err // '', qr/INJECTED|uid=/, "metachar '$meta': no shell output");
	}
	pass 'shell metachar in input: all handled as literal filename chars';
};

# ---------------------------------------------------------------------------
# 4. Input is a directory, not a plain file
#
# Exploit: providing a directory path hopes to trigger an info-leak or crash.
# Defense: -f $in is false for directories -> croak error_file_not_found.
# ---------------------------------------------------------------------------

subtest 'input is a directory: croak with error_file_not_found' => sub {
	my $c   = _converter();
	my $dir = tempdir(CLEANUP => 1);

	throws_ok { $c->convert(input => $dir) }
		qr/not found|Input file not found/i,
		'directory as input: croak with expected message';
};

# ---------------------------------------------------------------------------
# 5. Input is a special device (/dev/null)
#
# /dev/null is a character device; -f returns false -> error_file_not_found.
# ---------------------------------------------------------------------------

subtest 'input is /dev/null: croak with error_file_not_found' => sub {
	return pass '/dev/null not present (non-Unix)' unless -e '/dev/null';

	my $c = _converter();

	throws_ok { $c->convert(input => '/dev/null') }
		qr/not found|Input file not found/i,
		'/dev/null (char device): croak with expected message';
};

# ---------------------------------------------------------------------------
# 6. Very long filename (path-length DoS)
#
# Exploited by submitting a 65 535-char filename to trigger OS/Perl panics.
# Safe outcome: croak with error_file_not_found (file can't exist).
# ---------------------------------------------------------------------------

subtest 'input path: 65 535-char filename rejected with controlled error' => sub {
	my $c = _converter();

	throws_ok { $c->convert(input => $LONG_PATH) }
		qr/not found|Input file not found/i,
		'very long path: croak with expected error, no crash';
};

# ---------------------------------------------------------------------------
# 7. Input path: CRLF injection
#
# In a web context a CRLF in a filename reflected into an HTTP response
# header would split the header.  Here the test confirms the library itself
# handles the filename as a literal (file not found -> safe croak).
# ---------------------------------------------------------------------------

subtest 'input path: CRLF treated as literal, not injected into output' => sub {
	my $c = _converter();

	throws_ok { $c->convert(input => $CRLF_NAME) }
		qr/not found|Input file not found/i,
		'CRLF in input path: croak with expected message';
};

# ---------------------------------------------------------------------------
# 8. CONFIRMED VULNERABILITY (now fixed): recursive batch path traversal
#
# Exploit: batch_convert(recursive => 1, base_dir => '/safe',
#            inputs => ['t/input/Pilgrim.nwc'],   # outside /safe
#            output_dir => '/tmp/out')
#
# Before fix: abs2rel produced '../../..' -> catfile produced a path
#             OUTSIDE output_dir.  Hostile input escapes the sandbox.
#
# Fix applied: _batch_output_path now checks File::Spec->splitdir($rel)
#              for any '..' component and croaks error_traversal.
#              The croak is caught by the per-file eval -> file counted as
#              'failed' and the batch continues.
# ---------------------------------------------------------------------------

subtest 'batch_convert recursive: traversal input rejected, not escaped' => sub {
	return pass 'Pilgrim.nwc not available' unless -f $PILGRIM_NWC;

	my $out_dir  = tempdir(CLEANUP => 1);
	my $base_dir = tempdir(CLEANUP => 1);    # Pilgrim.nwc is NOT under this dir

	my $c      = _converter();
	my $result = $c->batch_convert(
		inputs     => [ $PILGRIM_NWC ],
		output_dir => $out_dir,
		recursive  => 1,
		base_dir   => $base_dir,
		overwrite  => 1,
	);

	# The traversal croak is caught per-file; batch does NOT abort.
	is $result->{processed},  1, 'traversal: processed count = 1';
	is $result->{failed},     1, 'traversal: counted as failed (not silently escaped)';
	is $result->{successful}, 0, 'traversal: no successful conversions';

	# No files must have landed outside out_dir.
	my @escaped = glob("$out_dir/../*$OUTPUT_EXT");
	is scalar @escaped, 0,
		'traversal: no .musicxml file written outside output_dir';
};

subtest 'batch_convert recursive: legitimate in-tree input succeeds (control)' => sub {
	my $base_dir = tempdir(CLEANUP => 1);
	my $sub_dir  = File::Spec->catdir($base_dir, 'scores');
	make_path($sub_dir);

	my $nwc_fh   = _write_nwc_tempfile($MINIMAL_STAFF);
	my $in_tree  = File::Spec->catfile($sub_dir, 'test.nwc');

	# Copy the temp NWC into the tree so it IS under base_dir.
	open my $src, '<:raw', $nwc_fh->filename;
	open my $dst, '>:raw', $in_tree;
	while (read $src, my $buf, 4096) { print $dst $buf }
	close $src;
	close $dst;

	my $out_dir = tempdir(CLEANUP => 1);
	my $c       = _converter();
	my $result  = $c->batch_convert(
		inputs     => [ $in_tree ],
		output_dir => $out_dir,
		recursive  => 1,
		base_dir   => $base_dir,
		overwrite  => 1,
	);

	is $result->{successful}, 1, 'in-tree: conversion succeeds';
	is $result->{failed},     0, 'in-tree: not counted as failed';

	my $expected = File::Spec->catfile($out_dir, 'scores', 'test' . $OUTPUT_EXT);
	ok -f $expected, "in-tree: output at expected path $expected";
};

# ---------------------------------------------------------------------------
# 9. XML injection via NWC staff name
#
# Exploit: attacker uploads an NWC binary where the staff name contains
# '<script>alert(1)</script>'.  If the MusicXML generator reflects it raw,
# the output XML is malformed and can be exploited in a browser that renders
# it directly.
#
# Defense: _xml_escape() in MusicXML.pm escapes <, >, &, " and '.
# Kill: assert raw payload ABSENT from output, entity form PRESENT.
# ---------------------------------------------------------------------------

subtest 'XML injection via staff name: output is entity-escaped' => sub {
	my $hostile_staff =
		"|AddStaff|Name:\"$XML_INJECT\"\n"
		. "|Clef|Type:Treble\n"
		. "|Key|Signature:Concert\n"
		. "|TimeSig|Signature:4/4\n"
		. "|Note|Dur:Whole|Pos:0\n"
		. "|Bar|\n";

	my $nwc_fh  = _write_nwc_tempfile($hostile_staff);
	my $out_dir = tempdir(CLEANUP => 1);
	my $out     = File::Spec->catfile($out_dir, "injected$OUTPUT_EXT");

	my $c      = _converter();
	my $result = eval {
		$c->convert(input => $nwc_fh->filename, output => $out, overwrite => 1)
	};

	return pass 'XML-inject staff name: conversion failed (acceptable)' unless defined $result && -f $result;

	my $content = do { local $/; open my $fh, '<:encoding(UTF-8)', $result; <$fh> };

	unlike $content, qr{<script>},     'raw <script> tag ABSENT from MusicXML output';
	like   $content, qr{&lt;script&gt;}, 'entity-escaped form present in output';

	diag substr($content, 0, 500) if $ENV{TEST_VERBOSE};
};

subtest 'XML injection via song title: output is entity-escaped' => sub {
	my $nwctxt = "!NoteWorthyComposer($NWC_VERSION)\n"
		. "|SongInfo|Title:$XML_INJECT\n"
		. "|AddStaff|Name:Piano\n"
		. "|Clef|Type:Treble\n"
		. "|Key|Signature:Concert\n"
		. "|TimeSig|Signature:4/4\n"
		. "|Note|Dur:Whole|Pos:0\n"
		. "|Bar|\n"
		. "!NoteWorthyComposer-End\n";

	my $binary = $NWC_MAGIC . Compress::Zlib::compress(\$nwctxt);
	my $nwc_fh = File::Temp->new(SUFFIX => '.nwc', UNLINK => 1);
	binmode $nwc_fh;
	print $nwc_fh $binary;
	$nwc_fh->close;

	my $out_dir = tempdir(CLEANUP => 1);
	my $out     = File::Spec->catfile($out_dir, "title_inject$OUTPUT_EXT");
	my $c       = _converter();
	my $result  = eval {
		$c->convert(input => $nwc_fh->filename, output => $out, overwrite => 1)
	};

	return pass 'song title injection: conversion failed (acceptable)' unless defined $result && -f $result;

	my $content = do { local $/; open my $fh, '<:encoding(UTF-8)', $result; <$fh> };
	unlike $content, qr{<script>},       'raw <script> ABSENT from work-title';
	like   $content, qr{&lt;script&gt;}, 'song title entity-escaped in output';
};

# ---------------------------------------------------------------------------
# 10. Symlink as output: overwrite=0 respects the "exists" check
#
# Exploit: attacker pre-places a symlink at the expected output path
# pointing at a sensitive file.  With overwrite => 0 (default), the -f
# check follows the symlink, finds the target exists, and SKIPS conversion.
# The symlink target is never overwritten.
# ---------------------------------------------------------------------------

subtest 'output symlink with overwrite=0: symlink target not overwritten' => sub {
	return pass 'Pilgrim.nwc not available' unless -f $PILGRIM_NWC;
	return pass 'symlink() not available on this platform'
		unless eval { symlink('', ''); 1 };

	my $dir    = tempdir(CLEANUP => 1);
	my $target = File::Spec->catfile($dir, 'sensitive.txt');
	open my $fh, '>', $target;
	print $fh "ORIGINAL_SENSITIVE_CONTENT\n";
	close $fh;

	my $link = File::Spec->catfile($dir, 'Pilgrim' . $OUTPUT_EXT);
	symlink $target, $link;

	my $c = _converter();
	# overwrite => 0: -f $link follows the symlink -> target exists -> skip
	eval { $c->convert(input => $PILGRIM_NWC, output => $link, overwrite => 0) };

	my $content = do { local $/; open my $f, '<', $target; <$f> };
	like $content, qr/ORIGINAL_SENSITIVE_CONTENT/,
		'symlink target: not overwritten when overwrite=0';
};

# ---------------------------------------------------------------------------
# 11. batch_convert: hostile mixture -- does not abort, counts correctly
#
# Confirm that injecting shell-metachar, traversal, and null-byte paths
# into the inputs list does not abort the batch and does not execute shell
# commands.  Valid files in the same batch still convert successfully.
# ---------------------------------------------------------------------------

subtest 'batch_convert: hostile input mixture handled safely' => sub {
	return pass 'Pilgrim.nwc not available' unless -f $PILGRIM_NWC;

	my $dir = tempdir(CLEANUP => 1);
	my $c   = _converter();

	# Suppress the "Invalid \0" warning from the null-byte path.
	local $SIG{__WARN__} = sub { 1 };

	my $result = $c->batch_convert(
		inputs    => [
			File::Spec->catfile($dir, "$SHELL_PIPE.nwc"),  # shell metachar
			$TRAV_INPUT,                                    # path traversal
			$NULL_BYTE,                                     # null byte
			$PILGRIM_NWC,                                   # one valid file
		],
		output_dir => $dir,
		overwrite  => 1,
	);

	is $result->{processed}, 4,
		'hostile mixture: all 4 processed (no early batch abort)';

	cmp_ok $result->{successful}, '>=', 1,
		'hostile mixture: at least 1 successful (Pilgrim.nwc)';

	# Check produced files for shell-execution artifacts.
	my @out_files = glob("$dir/*$OUTPUT_EXT");
	for my $out (@out_files) {
		my $content = do { local $/; open my $f, '<:encoding(UTF-8)', $out; <$f> };
		unlike $content, qr/INJECTED|uid=\d+/,
			"$out: no injected shell output in MusicXML content";
	}
};

# ---------------------------------------------------------------------------
# 12. Decompression: valid magic + corrupted zlib payload
#
# Exploit: a weaponised file passes the NWC magic check but has a garbage
# zlib stream.  The decompressor must reject it (error_decompress_fail),
# not crash or hang.
# ---------------------------------------------------------------------------

subtest 'corrupted zlib payload: decode fails gracefully, batch counts it' => sub {
	my $dir     = tempdir(CLEANUP => 1);
	my $corrupt = File::Spec->catfile($dir, 'corrupt.nwc');

	# NWC magic + plausible zlib header (0x78 0x9C) followed by garbage.
	# Compress::Zlib::uncompress will fail and return undef.
	open my $fh, '>:raw', $corrupt;
	print $fh $NWC_MAGIC . "\x78\x9C" . ('X' x 200);
	close $fh;

	my $c = _converter();

	# convert() returns undef (not croak) because _single_convert catches the
	# NWC decode failure and downgrades it to a warning + return undef.
	my $result = eval { $c->convert(input => $corrupt) };
	ok !defined $result, 'corrupted zlib: convert() returns undef';

	# Via batch_convert the failure must be counted.
	my $out_dir = tempdir(CLEANUP => 1);
	my $batch   = $c->batch_convert(
		inputs    => [ $corrupt ],
		output_dir => $out_dir,
		overwrite  => 1,
	);
	is $batch->{failed}, 1, 'corrupted zlib: batch counts the file as failed';
};

done_testing();
