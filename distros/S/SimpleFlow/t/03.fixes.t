#!/usr/bin/env perl

#
# Regression tests for the defects fixed in 0.18. Each block names the
# behaviour that was wrong before, so that a re-break is recognisable from the
# failure message alone.
#
# Blocks 1-4 were each confirmed to FAIL against 0.17 (the SimpleFlow-0.17/
# directory built from the uploaded tarball) before the fix went in. Blocks 1,
# 3 and 4 use no argument 0.15 did not accept; block 2 needs "timeout", which
# is 0.16.
#
# Blocks 5 and 6 are not regression tests: they cover the corners of the
# descriptor-level capture that replaced Capture::Tiny in 0.18 -- closed
# standard descriptors, and the caller's output layers -- where it has to
# behave as Capture::Tiny did. Both pass against 0.17 as well, which is the
# point. Block 5 needs "quiet" and "stdin", so 0.17 or later.
#
# Blocks 1-3 run task() in a fresh interpreter rather than in this one. The
# defect there is a forked child escaping into the caller's program;
# in-process, the escaped copy would be a second copy of this test file,
# emitting its own TAP. Blocks 5 and 6 do too, because they close or re-layer
# this process's standard handles.
#
# Nothing handed to a child perl as an argument may contain a double quote.
# On MSWin32 system(LIST) joins its arguments into one command line, wrapping
# any with a space in double quotes but not escaping the quotes inside, so the
# child receives a different program: 0.18's blocks 1 and 3 printed no
# RETURNED line at all on Strawberry Perl 5.42.2. The child code uses qq{}
# instead, and the command under test, which may itself be quoted, goes
# through %ENV, which reaches the child verbatim.
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use File::Spec;
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use File::Temp 'tempdir';
use SimpleFlow qw(task);

my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

# The same copy of the module this file loaded, not whatever is installed.
(my $lib_dir = $INC{'SimpleFlow.pm'}) =~ s{[/\\]SimpleFlow\.pm$}{};

# A name that is not a program anywhere: no PATH lookup can find it.
my $NO_SUCH = "simpleflow-no-such-command-$$";

#
# Run one task() in a child interpreter and return one hash per "RETURNED"
# line printed after it. The child prints that line once, after task()
# returns; a copy of the program that escaped from a fork prints it too, and
# says which it is. @ARGV is: timeout, form ('list' or 'string'); the command
# is in $ENV{SIMPLEFLOW_TEST_CMD}, for the reason given in the header.
#
my $CHILD = <<'CODE';
use strict; use warnings FATAL => 'all'; use SimpleFlow;
my ($timeout, $form) = @ARGV;
my $cmd = $ENV{SIMPLEFLOW_TEST_CMD};
my $parent = $$;
my $t = eval { task(cmd => ($form eq 'list' ? [$cmd] : $cmd), die => 0,
	($timeout ? (timeout => $timeout) : ())) };
print qq{\nRETURNED who=}, ($$ == $parent ? 'parent' : 'escaped'),
	' will.do=', ($t ? $t->{'will.do'} : 'died'),
	' exit=', ($t ? $t->{'exit'} : 'none'),
	' stdout=', ($t ? $t->{stdout} : ''), qq{\n};
CODE
sub run_child {
	my ($timeout, $form, $cmd) = @_;
	local $ENV{SIMPLEFLOW_TEST_CMD} = $cmd;
	my ($out) = capture { system($^X, "-I$lib_dir", '-e', $CHILD, $timeout, $form) };
	return map { { /(\w[\w.]*)=(\S*)/g } } ($out =~ /^RETURNED (.*)$/mg);
}

# --- 1. a command that cannot be launched ---------------------------------
# system() forks and then execs; when the exec failed, its child warned
# "Can't exec", which the module's "warnings FATAL" made a die in that child.
# The die unwound out of task() and the child ran the rest of the caller's
# program as a second copy, while the parent was handed the copy's exit
# status: under 0.17 a command that did not exist came back exit 0, "done",
# and everything after it in the pipeline ran twice.
foreach my $form ('list', 'string') {
	subtest "a missing command ($form form) is FAILED, and nothing escapes" => sub {
		my @returned = run_child(0, $form, $NO_SUCH);
		# positive sentinel first: the probe ran and task() returned
		cmp_ok(scalar(grep { $_->{who} eq 'parent' } @returned), '==', 1,
			'task() returned to the calling program exactly once');
		is(scalar(grep { $_->{who} eq 'escaped' } @returned), 0,
			'no forked copy of the caller ran on after task() (0.17: one did)');
		my ($parent) = grep { $_->{who} eq 'parent' } @returned;
		is($parent->{'will.do'}, 'FAILED', 'will.do is FAILED (0.17: "done")');
		# On MSWin32 a string whose direct spawn fails with ENOENT is retried
		# through cmd.exe (win32.c, so that shell builtins work), and cmd.exe
		# reports the missing program with a non-zero code of its own. That
		# code has not been observed -- there is no Windows perl here -- so
		# only its being non-zero is asserted.
		if ($form eq 'string' && $^O eq 'MSWin32') {
			isnt($parent->{'exit'}, 0, 'exit is non-zero, from cmd.exe (0.17: 0)');
		} else {
			is($parent->{'exit'},    -1,       'exit is -1, "could not be launched" (0.17: 0)');
		}
	};
}

# --- 2. the same, under a timeout -----------------------------------------
# _run_with_timeout forks and execs explicitly, and its failed exec died the
# same way before reaching the POSIX::_exit meant for it.
SKIP: {
	skip 'timeout needs fork() and POSIX process groups', 1 if $^O eq 'MSWin32';
	subtest 'a missing command under a timeout is FAILED, and nothing escapes' => sub {
		# 30 s is never reached: the exec fails at once
		my @returned = run_child(30, 'list', $NO_SUCH);
		cmp_ok(scalar(grep { $_->{who} eq 'parent' } @returned), '==', 1,
			'task() returned to the calling program exactly once');
		is(scalar(grep { $_->{who} eq 'escaped' } @returned), 0,
			'no forked copy of the caller ran on after task() (0.17: one did)');
		my ($parent) = grep { $_->{who} eq 'parent' } @returned;
		is($parent->{'will.do'}, 'FAILED', 'will.do is FAILED (0.17: "done")');
		# 127, the shell's "not found": the forked child has no way to hand
		# system()'s -1 back to the parent
		is($parent->{'exit'},    127,      'exit is 127 (0.17: 0)');
	};
}

# --- 3. a one-element array ref never reaches the shell --------------------
# An array-ref "cmd" is documented as run without a shell, but system(@list)
# hands a list of one to the shell, so under 0.17 cmd => ['a; b'] ran both
# commands. The command here is one the shell runs happily; as a program name
# it does not exist.
subtest 'a one-element array ref is a program name, not a shell command' => sub {
	my $shell_cmd = perl_cmd('print 42');
	my ($as_string) = run_child(0, 'string', $shell_cmd);
	# positive control: the shell does run this string, and prints 42
	is($as_string->{stdout}, '42', 'the command works when given to the shell');
	my @returned = run_child(0, 'list', $shell_cmd);
	cmp_ok(scalar @returned, '==', 1, 'task() returned exactly once');
	is($returned[0]{'will.do'}, 'FAILED', 'as a one-element array ref it is FAILED (0.17: "done")');
	is($returned[0]{stdout},    '',       'and the shell never ran it (0.17: printed 42)');
};

# --- 4. an in-memory STDOUT does not defeat the capture --------------------
# Capture::Tiny redirected the STDOUT glob, and a glob opened on a scalar has
# no descriptor to redirect, so under 0.17 the command wrote straight past it
# onto the real fd 1 and the record's stdout came back empty. task() now
# redirects the descriptor, which is what the command inherits.
subtest 'the command is captured when STDOUT is an in-memory handle' => sub {
	my ($in_memory, $t) = ('');
	my ($escaped) = capture {
		local *STDOUT;
		open STDOUT, '>', \$in_memory or die "cannot open an in-memory STDOUT: $!";
		$t = task(cmd => perl_cmd('print uc q{sentinel}'), die => 0);
	};
	# positive sentinel: task() ran and printed its record somewhere
	cmp_ok(length($in_memory) + length($escaped), '>', 0, 'task() ran and printed its record');
	is($t->{stdout}, 'SENTINEL', "the command's output is in the record (0.17: '')");
	unlike($escaped, qr/^SENTINEL/m, 'and did not escape onto the real fd 1 (0.17: it did)');
};

my $dir = tempdir(CLEANUP => 1);

#
# Run $code in a fresh interpreter, with the path of a results file in
# $ARGV[0], and return what it wrote there. The results go to a file, not to
# STDOUT, because the code may have closed STDOUT.
#
sub run_probe {
	my ($name, $code) = @_;
	my $results = File::Spec->catfile($dir, "$name.results");
	capture { system($^X, "-I$lib_dir", '-e', $code, $results) };
	open my $fh, '<', $results or return '(the probe wrote no results)';
	local $/;
	return scalar <$fh>;
}

# --- 5. closed standard descriptors ----------------------------------------
# A daemon may have closed 0, 1 and 2 before calling task(). The capture files
# must then not land on those numbers, the command must still be captured,
# and the descriptors must be closed again afterwards, not left open on
# something the caller never asked for. With the plugging taken out of
# _capture this fails: the temporary files take 0 and 1, stdout and stderr
# both come back "errout", and 1 and 2 are left open.
subtest 'closed standard descriptors are plugged for the run and closed after' => sub {
	my $got = run_probe('closed', <<'CODE');
use strict; use warnings FATAL => 'all'; use SimpleFlow; use POSIX ();
open my $res, '>', $ARGV[0] or die;
close STDIN; close STDOUT; close STDERR;
my $t = task(cmd => [$^X, '-e', 'print q{out}; print STDERR q{err}'],
	quiet => 1, stdin => 'inherit');
my @after = map { my $d = POSIX::dup($_); defined $d ? 'open' : 'closed' } 0 .. 2;
print {$res} join('|', $t->{'will.do'}, $t->{stdout}, $t->{stderr}, @after);
CODE
	is($got, 'done|out|err|closed|closed|closed',
		'the command ran and was captured, and 0, 1 and 2 are closed again');
};

# --- 6. the caller's output layers are honoured ----------------------------
# Capture::Tiny read the capture back through the layers of the caller's own
# STDOUT, so a caller that had said binmode STDOUT, ':encoding(UTF-8)' got
# decoded characters. The replacement must do the same: two bytes of UTF-8
# for one e-acute are one character in the record.
subtest "the capture is decoded through the caller's STDOUT layers" => sub {
	my $got = run_probe('layers', <<'CODE');
use strict; use warnings FATAL => 'all'; use SimpleFlow;
open my $res, '>', $ARGV[0] or die;
binmode STDOUT, ':encoding(UTF-8)';
my $t = task(cmd => [$^X, '-e', 'binmode STDOUT; print qq{\xc3\xa9}'], quiet => 1);
print {$res} join('|', length $t->{stdout}, ord $t->{stdout});
CODE
	is($got, '1|233', 'the command printed UTF-8 and the record holds one character, U+00E9');
};

done_testing();
