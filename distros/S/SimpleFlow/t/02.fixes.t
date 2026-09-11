#!/usr/bin/env perl

#
# Tests for the defects fixed in 0.16, and for the options added alongside
# them. Each block names the behaviour that was wrong before, so that a
# re-break is recognisable from the failure message alone.
#
# Blocks 1-11 are regression tests: every one of them was confirmed to FAIL
# against 0.15 before the corresponding fix went in, which is the only real
# evidence that a regression test tests anything. They therefore use no
# argument that 0.15 did not already accept, so the file can be re-run against
# an old checkout to check that they still catch what they were written for.
# Blocks 12-16 cover options that are new in 0.16 (stale, input.file, quiet,
# timeout) and cannot run against an older module at all.
#
# Block 17 is a regression test for a defect in 0.16 itself, reported by a CPAN
# tester: it was confirmed to FAIL against 0.16 before that fix went in, and it
# too uses only arguments 0.15 accepted.
#
# Two of these tests would once have passed for the wrong reason -- an assertion
# that something is empty passes when the probe producing it never ran. Those
# now assert a positive sentinel first; the comments at each site say so.
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception;
use Capture::Tiny 'capture';
use File::Temp qw(tempfile tempdir);
use File::Spec;
use SimpleFlow qw(task say2);

# Portability setup consistent with 01.t
my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

my $dir = tempdir(CLEANUP => 1);

#
# task() prints the result record to the terminal unless "quiet", and its
# failure paths dump the arguments with "p" and say what is wrong on STDERR
# before they warn or die. That is the module working as documented, but in a
# test file it buries the TAP: a clean, wholly successful run of this file
# printed 425 lines of record dumps and three backtraces, which reads exactly
# like a crash. quietly() captures both streams for one call and returns what
# the call returned; an exception still propagates, so throws_ok and dies_ok
# work through it.
#
# Capturing rather than passing "quiet => 1" is deliberate: blocks 1-11 have to
# stay runnable against 0.15, which has no "quiet" (see the header), and
# capturing changes nothing about the arguments task() is given. Where the
# printed text is itself the point -- blocks 11, 14 and 17 -- it is measured,
# not captured, and those blocks are left alone.
#
sub quietly (&) {
	my $code = shift;
	my (undef, undef, @result) = capture { $code->() };
	return wantarray ? @result : $result[0];
}

# Where SimpleFlow was actually loaded from. Several tests below need to run a
# *fresh* interpreter -- to prove a hard kill flushes the log, or that nothing
# leaks into main:: -- and those child processes have to load the same copy of
# the module that this test file did, not whatever is installed system-wide.
my $module_path = $INC{'SimpleFlow.pm'};
(my $lib_dir = $module_path) =~ s{[/\\]SimpleFlow\.pm$}{};

# --- 1. die => 0 must report the failure -----------------------------------
# The 'will.do' => 'FAILED' assignment used to live inside the "if (die)"
# branch, so it could only ever run on the path that immediately died. Under
# die => 0 -- the mode in which the caller is expected to read will.do -- a
# command that exited non-zero was reported as 'done', and nothing warned.
subtest 'die => 0 reports a non-zero exit as FAILED' => sub {
	my @warnings;
	my $t;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$t = quietly { task(cmd => perl_cmd('exit 3'), die => 0) };
	}
	is($t->{'exit'},    3,        'exit code is reported');
	is($t->{'will.do'}, 'FAILED', 'will.do says FAILED, not "done"');
	ok(scalar(grep { /exited 3/ } @warnings), 'a warning names the exit code');

	# a successful command must NOT be marked FAILED
	my $ok = quietly { task(cmd => perl_cmd('exit 0'), die => 0) };
	is($ok->{'will.do'}, 'done', 'a successful command is still "done"');

	# the other route to FAILED: the command succeeded but did not produce
	# what it declared. 01.t already checks this does not crash under
	# die => 0; what matters here is that the caller can SEE the failure.
	my $never_made = "$dir/never-made.dat";
	# capture takes the lot: the 0-size warning, which is not what is under
	# test, and the "has these output files missing" report, which goes to
	# STDERR directly rather than through warn and so used to print here
	my (undef, $missing_err, $missing) = capture { task(
		cmd            => perl_cmd('exit 0'),
		'output.files' => $never_made,
		die            => 0,
	) };
	like($missing_err, qr/should have been made but are missing/,
		'the missing output is named on stderr');
	is($missing->{'exit'},    0,        'the command itself succeeded');
	is($missing->{'will.do'}, 'FAILED', 'a missing declared output is FAILED even with die => 0');
};

# --- 2. the log filehandle is autoflushed ----------------------------------
# Without autoflush the record of the very task that killed the run stays in
# stdio's buffer. Checking the on-disk size while the handle is still open is
# the direct test: buffered output would leave 0 bytes there.
subtest 'log filehandle is autoflushed' => sub {
	my $log_name = "$dir/flush.log";
	open my $log, '>', $log_name or die "cannot write $log_name: $!";
	# say2 says to both, so its terminal half is captured and checked here
	# instead of being printed
	my ($said_out) = capture { say2('a line that must reach the disk immediately', $log) };
	like($said_out, qr/must reach the disk immediately/, 'say2 writes to the terminal too');
	cmp_ok(-s $log_name, '>', 0, 'say2 output is on disk before the handle is closed');

	my $before = -s $log_name;
	quietly { task(cmd => perl_cmd('exit 0'), 'log.fh' => $log) };
	cmp_ok(-s $log_name, '>', $before, 'the task record is on disk before the handle is closed');
	close $log;
};

# --- 3. an undefined filename is an argument error, not a crash ------------
# 0.14 added a "defined" guard to the 0-length check, but the -f -r filetest
# ran first, so an undef element still died as "Use of uninitialized value $_
# in -r at SimpleFlow.pm line 121" under warnings FATAL => 'all'.
subtest 'undefined and 0-length filenames are rejected by name' => sub {
	my ($ifh, $real) = tempfile(DIR => $dir); print {$ifh} 'x'; close $ifh;

	throws_ok {
		quietly { task(cmd => perl_cmd('exit 0'), 'input.files' => [$real, undef]) };
	} qr/undefined or 0-length filenames/,
		'undef in an input.files array is an argument error, not an uninitialized-value crash';

	# The 0-length input check used to be unreachable: '' fails -f, so
	# it was reported as "missing or unreadable" instead of as a bad name.
	throws_ok {
		quietly { task(cmd => perl_cmd('exit 0'), 'input.files' => '') };
	} qr/undefined or 0-length filenames/,
		'a 0-length input.files name is reported as a 0-length name';

	throws_ok {
		quietly { task(cmd => perl_cmd('exit 0'), 'output.files' => [$real, '']) };
	} qr/undefined or 0-length filenames/,
		'a 0-length output.files name is reported as a 0-length name';

	# the message must point at the offending position
	throws_ok {
		quietly { task(cmd => perl_cmd('exit 0'), 'input.files' => [$real, '']) };
	} qr/index 1/, 'the message names the index of the bad filename';
};

# --- 4. cmd is type-checked ------------------------------------------------
# Any reference used to be stringified straight into the shell, so
# task(cmd => ['echo','hi']) ran the literal command "ARRAY(0x...)".
subtest 'cmd is validated' => sub {
	throws_ok { quietly { task(cmd => { bad => 'hash' }) } } qr/must be a string or an array ref/,
		'a hash ref cmd is refused rather than stringified into the shell';
	throws_ok { quietly { task(cmd => '') } } qr/empty string/,
		'an empty cmd is refused';
	throws_ok { quietly { task(cmd => []) } } qr/empty array ref/,
		'an empty array ref cmd is refused';
	throws_ok { quietly { task(cmd => [$^X, undef]) } } qr/undefined elements/,
		'an array ref cmd holding undef is refused';

	# an array ref is now the shell-free form, and really does run
	my $t = quietly { task(cmd => [$^X, '-e', 'print q{no shell here}'], die => 0) };
	is($t->{stdout}, 'no shell here', 'an array ref cmd runs without a shell');
	is($t->{'exit'}, 0,               'an array ref cmd reports its exit code');
	is($t->{cmd}, "$^X -e print q{no shell here}",
		'the record shows the array ref cmd space-joined');

	# The decisive test: an argument full of shell metacharacters must arrive
	# at the command byte for byte. Handed to a shell, $HOME would expand,
	# `date` would run, * would glob and ; would end the command.
	my $metacharacters = 'a $HOME `date` * ; b';
	my $literal = quietly { task(cmd => [$^X, '-e', 'print $ARGV[0]', $metacharacters], die => 0) };
	is($literal->{stdout}, $metacharacters,
		'an array ref cmd passes shell metacharacters through untouched');
};

# --- 5. the 0-length output message has balanced parentheses ---------------
subtest 'error messages are well formed' => sub {
	my $err = '';
	eval { quietly { task(cmd => perl_cmd('exit 0'), 'output.file' => '') } };
	$err = $@;
	# without this the counts would both be 0 and the test would pass even if
	# the call had never died
	isnt($err, '', 'the 0-length filename really did die (guards against a vacuous pass)');
	my $opens  = () = $err =~ /\(/g;
	my $closes = () = $err =~ /\)/g;
	is($opens, $closes, 'the 0-length filename message has balanced parentheses');
};

# --- 6. the record has the same shape on every path ------------------------
# exit / signal / stdout / stderr used to be absent after a skip or a dry run,
# so a caller running under warnings FATAL => 'all' -- as this module itself
# recommends -- died just by reading $t->{'exit'}.
subtest 'the result record has a uniform shape' => sub {
	my @always = qw(exit signal stdout stderr duration timed.out will.do done cmd dir);

	my ($ofh, $exists) = tempfile(DIR => $dir); print {$ofh} 'x'; close $ofh;
	my %path = (
		'a completed run' => quietly { task(cmd => perl_cmd('exit 0')) },
		'a skipped run'   => quietly { task(cmd => perl_cmd('exit 0'), 'output.files' => $exists) },
		'a dry run'       => quietly { task(cmd => perl_cmd('exit 0'), 'dry.run' => 1) },
	);
	for my $what (sort keys %path) {
		my $t = $path{$what};
		my @absent = grep { not defined $t->{$_} } @always;
		is_deeply(\@absent, [], "every documented field is defined after $what")
			or diag("missing: @absent");
		# the shape that used to be fatal for the caller
		lives_ok { my $unused = $t->{'exit'} + $t->{signal} + $t->{duration} }
			"arithmetic on the record's numeric fields is safe after $what";
	}
	is($path{'a skipped run'}{done}, 'before', 'the skipped run really did skip');
};

# --- 7. skip detection and the post-run check agree ------------------------
# Skipping used to test a bare -f while the post-run check tested -f -r, so an
# output that existed but could not be read counted as "already done".
SKIP: {
	skip 'file permissions do not work the same way on Windows', 2 if $^O eq 'MSWin32';
	skip 'running as root: an unreadable file is still readable', 2 if $< == 0;
	my $unreadable = "$dir/unreadable.dat";
	open my $ufh, '>', $unreadable or die; print {$ufh} 'x'; close $ufh;
	chmod 0000, $unreadable;
	my (undef, $unreadable_err, $t) = capture { task(cmd => qq{$PERL -e "print 1" > "$unreadable"},
		'output.files' => $unreadable, die => 0) };
	isnt($t->{done}, 'before', 'an unreadable output file does not count as already done');
	# the redirect cannot write the file, so the shell exits non-zero and
	# die => 0 warns: captured, and checked, because a silent failure here
	# would be the 0.16 defect over again
	like($unreadable_err, qr/exited \d+/, 'the failed redirect is reported on stderr');
	chmod 0644, $unreadable;
}

# --- 8. loading SimpleFlow does not pollute the caller's namespace ---------
# "use DDP" and "use Cwd 'getcwd'" used to sit above the package statement, so
# p / np / getcwd were imported into main:: of every program that loaded it.
subtest 'no namespace pollution' => sub {
	# The check has to run in a fresh interpreter that loads nothing but
	# SimpleFlow: this test file has DDP in scope already. The probe is
	# written to a FILE rather than passed with -e, because a shell would eat
	# the $_ in it -- and a probe that dies prints nothing, which would make an
	# "is($leaked, '')" assertion pass for the wrong reason. Hence the SENTINEL:
	# the probe has to positively report success, not merely stay silent.
	my $probe = "$dir/namespace_probe.pl";
	open my $pfh, '>', $probe or die "cannot write $probe: $!";
	print {$pfh} <<'PROBE';
use strict;
use warnings;
use SimpleFlow;
no strict 'refs'; # a symbolic lookup is the only way to ask "was this imported?"
my @leaked = grep { defined &{"main::$_"} } qw(p np getcwd);
print 'SENTINEL:', join(',', @leaked);
PROBE
	close $pfh;
	my $result = `$PERL -I"$lib_dir" "$probe"`;
	like($result, qr/^SENTINEL:/, 'the probe ran (guards against a vacuous pass)');
	is($result, 'SENTINEL:', 'p, np and getcwd are not imported into the caller')
		or diag("leaked into main:: -> $result");
};

# --- 9. the log really does survive a hard kill --------------------------
# The autoflush test above checks the proxy (bytes on disk while the handle is
# open). This checks the thing that actually went wrong: a process killed
# outright, with no chance to run END blocks or flush at global destruction.
SKIP: {
	skip 'SIGKILL is not available on Windows', 1 if $^O eq 'MSWin32';
	subtest 'the log survives SIGKILL' => sub {
		my $log_name = "$dir/sigkill.log";
		my $script   = "$dir/sigkill_probe.pl";
		open my $sfh, '>', $script or die "cannot write $script: $!";
		print {$sfh} <<"PROBE";
use strict;
use warnings;
use lib '$lib_dir';
use SimpleFlow qw(task say2);
open my \$log, '>', '$log_name' or die;
task(cmd => qq{"\$^X" -e "print q{payload}"}, 'log.fh' => \$log);
say2('the line that must survive', \$log);
kill 'KILL', \$\$;   # an OOM kill or a scheduler eviction looks like this
PROBE
		close $sfh;
		my $devnull = File::Spec->devnull;
		# The task() inside the probe above is deliberately NOT wrapped in
		# quietly(): it runs in a child interpreter that never defines it, and
		# the redirect below already keeps the child's record dump off this
		# terminal. Only the log matters here.
		system(qq{$PERL "$script" > $devnull 2> $devnull}); # dies by SIGKILL; only the log matters
		ok(-e $log_name, 'the log file exists after the kill');
		my $content = do { open my $rfh, '<', $log_name or die; local $/; <$rfh> };
		like($content, qr/the line that must survive/,
			'the last line written before the kill reached the disk');
		like($content, qr/\bexit\b/,
			'the task record -- not just the command line -- reached the disk');
	};
}

# --- 10. $VERSION is a quoted string --------------------------------------
# As a bare number it is stringified through %g, so a future 0.20 would become
# "0.2" and compare as OLDER than "0.15" on CPAN.
#
# Two decimal places or more, not exactly two: this asked for exactly two until
# 0.161, which is a point release on 0.16 and keeps three on purpose. What %g
# would destroy is a trailing zero, so the invariant is that every decimal the
# source wrote is still there -- 0.161 has three digits and prints three.
subtest '$VERSION is a quoted string' => sub {
	my $source = do { open my $fh, '<', $module_path or die; local $/; <$fh> };
	like($source, qr/our \s* \$VERSION \s* = \s* ['"]/x,
		'the $VERSION literal is quoted in the source');
	my ($literal) = $source =~ /our \s* \$VERSION \s* = \s* ['"]([^'"]+)['"]/x;
	like($SimpleFlow::VERSION, qr/^\d+\.\d\d+$/,
		'the version keeps at least two decimal places (a bare 0.20 would stringify to "0.2")');
	# The literal and what the module ends up with have to be the same string.
	# The pattern above cannot stand in for this: with the quotes taken off
	# 0.161 the module still reports "0.161" and the pattern passes, and only
	# this comparison fails (checked both ways, 2026-09-10). It is the digits
	# that decide whether %g destroys anything, so the shorter the version the
	# more the pattern misses.
	is($SimpleFlow::VERSION, $literal,
		'$VERSION is the string the source wrote, digit for digit');
};

# --- 11. string_max is capped ----------------------------------------------
# string_max used to be raised to the length of the captured output, so a
# chatty command had its entire stdout echoed to the terminal and the log.
subtest 'a large capture is not echoed in full' => sub {
	# This has to run in a subprocess with REAL file descriptors. Redirecting
	# this process's STDOUT to an in-memory scalar defeats Capture::Tiny --
	# it cannot dup a handle that has no fd -- so the child's output never gets
	# captured, the record comes out small, and the test would pass on any
	# module at all. A subprocess writing to an actual file reproduces the
	# original flood exactly.
	my $bytes        = 200_000;
	my $log_name     = "$dir/big.log";
	my $terminal_out = "$dir/big.terminal";
	my $capture_len  = "$dir/big.capturelen";
	my $script       = "$dir/big_probe.pl";

	open my $sfh, '>', $script or die "cannot write $script: $!";
	print {$sfh} <<"PROBE";
use strict;
use warnings;
use lib '$lib_dir';
use SimpleFlow qw(task);
open my \$log, '>', '$log_name' or die;
my \$t = task(cmd => qq{"\$^X" -e "print q{x} x $bytes"}, 'log.fh' => \$log, die => 0);
close \$log;
open my \$c, '>', '$capture_len' or die;
print {\$c} length \$t->{stdout};
close \$c;
PROBE
	close $sfh;
	system(qq{$PERL "$script" > "$terminal_out"}) == 0
		or die "the big-capture probe failed to run";

	# the probe must have got as far as recording the capture length, or the
	# size assertions below would be measuring nothing
	my $recorded = do { open my $rfh, '<', $capture_len or die; local $/; <$rfh> };
	is($recorded, $bytes, 'the full capture is still available on the result (and the probe ran)');

	cmp_ok(-s $terminal_out, '>', 0,      'the record is printed to the terminal at all');
	cmp_ok(-s $terminal_out, '<', $bytes, 'but the terminal does not receive the whole capture');
	cmp_ok(-s $log_name,     '>', 0,      'the record is written to the log at all');
	cmp_ok(-s $log_name,     '<', $bytes, 'but the log does not receive the whole capture either');
};

# --- 12. staleness (stale => 1) --------------------------------------------
subtest 'stale => 1 re-runs when an input is newer than an output' => sub {
	my ($in, $out) = ("$dir/stale.in", "$dir/stale.out");
	open my $o, '>', $out; print {$o} 'old result'; close $o;
	sleep 2; # mtime has 1-second granularity on some filesystems
	open my $i, '>', $in;  print {$i} 'new input';  close $i;

	my $without = task(
		cmd            => qq{$PERL -e "print q{regenerated}" > "$out"},
		'input.files'  => $in,
		'output.files' => $out,
		quiet          => 1,
	);
	is($without->{done}, 'before', 'without stale => 1 the existing output is accepted (unchanged default)');

	my $with = task(
		cmd            => qq{$PERL -e "print q{regenerated}" > "$out"},
		'input.files'  => $in,
		'output.files' => $out,
		stale          => 1,
		quiet          => 1,
	);
	is($with->{done},          'now', 'with stale => 1 the out-of-date output is rebuilt');
	is($with->{'out.of.date'}, 1,     'the record says why it re-ran');

	# now that the output is newer than the input, stale => 1 must skip again
	my $fresh = task(
		cmd            => qq{$PERL -e "print q{regenerated}" > "$out"},
		'input.files'  => $in,
		'output.files' => $out,
		stale          => 1,
		quiet          => 1,
	);
	is($fresh->{done},          'before', 'an up-to-date output is skipped even with stale => 1');
	is($fresh->{'out.of.date'}, 0,        'and is not marked out of date');
};

# --- 13. input.file, the single-file convenience form ----------------------
subtest 'input.file (single file)' => sub {
	my ($ifh, $i1) = tempfile(DIR => $dir); print {$ifh} 'abc'; close $ifh; # 3 bytes
	my $t = quietly { task(cmd => perl_cmd('exit 0'), 'input.file' => $i1) };
	is_deeply($t->{'input.files'}, [$i1], 'input.file is folded into the input.files arrayref');
	is($t->{'input.file.size'}{$i1}, 3,   'input.file.size reports the byte count');

	throws_ok { quietly { task(cmd => perl_cmd('exit 0'), 'input.file' => $i1, 'input.files' => $i1) } }
		qr/cannot both be given/, 'input.file and input.files are mutually exclusive';
	throws_ok { quietly { task(cmd => perl_cmd('exit 0'), 'input.file' => [$i1]) } }
		qr/isn't allowed for "input\.file"/, 'input.file refuses a reference';
	throws_ok { quietly { task(cmd => perl_cmd('exit 0'), 'input.file' => "$dir/definitely-not-here") } }
		qr/missing or are not readable/, 'a missing input.file is still caught';
};

# --- 14. quiet => 1 silences the terminal but not the log ------------------
subtest 'quiet => 1' => sub {
	# Both directions, so that the test cannot pass vacuously: if the STDOUT
	# redirection below ever stopped working, the quiet => 0 case would come
	# back empty too and give the game away.
	my %captured;
	my %log_size;
	# The command's own "hush" does not land in %captured and never did: file
	# descriptor 1 still points at the real terminal while STDOUT is an
	# in-memory handle, so Capture::Tiny inside task() has no fd to dup and the
	# child writes straight past the redirect (the same limitation block 11
	# describes). The outer capture here is what keeps that off the terminal;
	# $escaped is asserted on below so the arrangement cannot rot silently.
	my $escaped = '';
	for my $quiet (0, 1) {
		my $log_name = "$dir/quiet-$quiet.log";
		open my $log, '>', $log_name or die;
		$captured{$quiet} = '';
		{
			my ($out) = capture {
				local *STDOUT;
				open STDOUT, '>', \$captured{$quiet} or die;
				task(cmd => perl_cmd('print q{hush}'), 'log.fh' => $log, quiet => $quiet);
			};
			$escaped .= $out;
		}
		close $log;
		$log_size{$quiet} = -s $log_name;
	}
	is($escaped, 'hushhush', "the command's own output goes past the in-memory STDOUT, both times");
	cmp_ok(length $captured{0}, '>', 0, 'without quiet the record reaches STDOUT');
	is($captured{1}, '',                'with quiet => 1 nothing reaches STDOUT');
	cmp_ok($log_size{1}, '>', 0,        'the log is still written when quiet => 1');
	cmp_ok($log_size{1}, '>=', $log_size{0} - 8,
		'and the log is no shorter than it is without quiet');
};

# --- 15. timeout -----------------------------------------------------------
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 4 if $^O eq 'MSWin32';
	subtest 'timeout kills a command that runs too long' => sub {
		my @warnings;
		my $t;
		my $t0 = time;
		{
			local $SIG{__WARN__} = sub { push @warnings, $_[0] };
			$t = task(cmd => qq{$PERL -e "sleep 30"}, timeout => 2, die => 0, quiet => 1);
		}
		my $elapsed = time - $t0;
		cmp_ok($elapsed, '<', 20, 'the command was killed rather than left to finish');
		is($t->{'timed.out'}, 1,        'timed.out is set');
		is($t->{'will.do'},   'FAILED', 'a timed-out command is FAILED');
		ok(scalar(grep { /timeout/ } @warnings), 'a warning explains the timeout');
	};

	subtest 'timeout does not disturb a command that finishes in time' => sub {
		# quiet => 1 silences the record, not the warning a failure earns
		my (undef, $err, $t) = capture { task(cmd => perl_cmd('exit 5'), timeout => 30,
			die => 0, quiet => 1) };
		like($err, qr/exited 5\b/, 'the exit is still warned about under quiet => 1');
		is($t->{'exit'},      5, 'the exit code is decoded normally under a timeout');
		is($t->{'timed.out'}, 0, 'timed.out is 0 when the limit was not reached');
	};

	dies_ok { quietly { task(cmd => perl_cmd('exit 0'), timeout => 'soon') } }
		'a non-numeric timeout is refused';

	subtest 'a timed-out command dies by default' => sub {
		throws_ok { task(cmd => qq{$PERL -e "sleep 30"}, timeout => 2, quiet => 1) }
			qr/timeout/, 'the default die => 1 stops the pipeline on a timeout';
	};
}

# --- 16. a timed-out command leaves no orphan doing work ------------------
# Killing only the shell would leave its children running: the point of the
# process group. The command writes a marker file AFTER its sleep, so the
# marker appearing at all proves something outlived the timeout.
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 1 if $^O eq 'MSWin32';
	subtest 'a timed-out command leaves no orphan behind' => sub {
		my $marker = "$dir/orphan.marker";
		my $slow   = "$dir/orphan.pl";
		open my $ofh, '>', $slow or die;
		print {$ofh} "sleep 4; open my \$f, '>', '$marker' or die; print {\$f} 1; close \$f;\n";
		close $ofh;
		# "&& true" guarantees a shell is involved, so the perl process is a
		# GRANDchild: exactly the case where killing the direct child is not
		# enough.
		my (undef, $err, $t) = capture { task(cmd => qq{$PERL "$slow" && true}, timeout => 1,
			die => 0, quiet => 1) };
		is($t->{'timed.out'}, 1, 'the task reports the timeout');
		like($err, qr/timeout/, 'and says on stderr that it killed the command');
		sleep 6; # comfortably past the 4s the orphan would have needed
		ok(! -e $marker, 'the killed command did not go on to do its work as an orphan');
	};
}

# --- 17. the cap must not depend on Data::Printer's version ---------------
# "string_max" is a Data::Printer property that arrived in 0.99_001
# (2018-04-21, per that distribution's Changes); every earlier release
# silently ignores a property it does not know. 0.16 capped the record by
# handing string_max to Data::Printer and leaving the clipping to it, so on a
# CPAN tester running Data::Printer 0.38 nothing was capped at all: a
# 200,000-character capture wrote 200,927 bytes to the terminal and 200,914
# bytes to the log (report from perl 5.20.0, 2026-09-05). SimpleFlow clips the
# strings itself now, before they are printed.
#
# The probe loads a stub DDP that ignores every property it is given -- which
# is precisely what those releases did -- because that is the only way to
# reproduce the flood on a machine whose Data::Printer is current, and it
# needs no network and nothing installed.
subtest 'the record is clipped whatever Data::Printer does with string_max' => sub {
	my $bytes        = 200_000;
	my $stub_dir     = File::Spec->catdir($dir, 'old_ddp');
	my $log_name     = "$dir/version.log";
	my $terminal_out = "$dir/version.terminal";
	my $capture_len  = "$dir/version.capturelen";
	my $script       = "$dir/version_probe.pl";

	mkdir $stub_dir or die "cannot create $stub_dir: $!";
	open my $stub, '>', File::Spec->catfile($stub_dir, 'DDP.pm')
		or die "cannot write the stub DDP: $!";
	print {$stub} <<'STUB';
# A stand-in for Data::Printer as it was before 0.99_001: it exports "p" with
# the same prototype, and it drops every property it is handed -- string_max
# included -- on the floor. "stub-DDP" heads each dump so that the test can
# tell this printer really was the one that ran.
package DDP;
use strict;
use warnings;
sub import {
	my $caller = caller; # the properties, if any, are ignored
	no strict 'refs';
	*{$caller . '::p'}  = \&p;
	*{$caller . '::np'} = \&np;
	return;
}
sub _dump {
	my $thing = shift;
	return 'undef' unless defined $thing;
	return join('',  map {_dump($thing->{$_}) . "\n"} sort keys %$thing) if ref $thing eq 'HASH';
	return join('',  map {_dump($_) . "\n"} @$thing)                     if ref $thing eq 'ARRAY';
	return _dump($$thing) if (ref $thing eq 'REF') || (ref $thing eq 'SCALAR');
	return "$thing";
}
sub p (\[@$%&];%) {
	my ($ref, %property) = @_;
	my $text = "stub-DDP\n" . _dump($ref);
	if (ref $property{output}) {
		print {$property{output}} $text;
	} else {
		print STDOUT $text;
	}
	return $text;
}
sub np { return _dump($_[0]) }
1;
STUB
	close $stub;

	open my $sfh, '>', $script or die "cannot write $script: $!";
	print {$sfh} <<"PROBE";
use strict;
use warnings;
use lib '$lib_dir';
use lib '$stub_dir'; # ahead of the real Data::Printer in \@INC
use SimpleFlow qw(task);
open my \$log, '>', '$log_name' or die;
my \$t = task(cmd => qq{"\$^X" -e "print q{x} x $bytes"}, 'log.fh' => \$log, die => 0);
close \$log;
open my \$c, '>', '$capture_len' or die;
print {\$c} length \$t->{stdout};
close \$c;
PROBE
	close $sfh;
	system(qq{$PERL "$script" > "$terminal_out"}) == 0
		or die "the old-Data::Printer probe failed to run";

	# the probe must have got as far as recording the capture length, or the
	# size assertions below would be measuring nothing
	my $recorded = do { open my $rfh, '<', $capture_len or die; local $/; <$rfh> };
	is($recorded, $bytes, 'the full capture is still available on the result (and the probe ran)');

	my $printed = do { open my $tfh, '<', $terminal_out or die; local $/; <$tfh> };
	# without this the test would pass on the unfixed module wherever the
	# installed Data::Printer happens to honour string_max itself
	like($printed, qr/stub-DDP/, 'the printer that ignores string_max is the one that ran');
	like($printed, qr/\Q(...skipping\E \d+ \Qchars...)\E/,
		'the clipped field says how much was dropped');
	cmp_ok(length $printed, '>', 0,      'the record is printed to the terminal at all');
	cmp_ok(length $printed, '<', $bytes, 'but the terminal does not receive the whole capture');
	cmp_ok(-s $log_name,    '>', 0,      'the record is written to the log at all');
	cmp_ok(-s $log_name,    '<', $bytes, 'but the log does not receive the whole capture either');
};

done_testing();
