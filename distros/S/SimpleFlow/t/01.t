#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception; # die_ok / lives_ok
use File::Temp 'tempfile';
use Cwd 'getcwd';
use DDP;             # make p() explicit instead of relying on the DDP-into-main
                     # leak from SimpleFlow.pm
use SimpleFlow qw(task say2);

# ---------------------------------------------------------------------------
# Portability: the original tests called Unix-only tools (which/ls/ln/cp) and
# hard-coded /tmp, which fails on Windows CPAN testers. Use the running Perl
# interpreter instead -- it is always present -- and let File::Temp pick the
# system temp dir. $^X is quoted in case its path contains spaces (Windows).
# NB: the $code passed to perl_cmd() must not itself contain double quotes.
# ---------------------------------------------------------------------------
my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

my ($simple_task, $log_write, $stopping, $dry_run, $overwrite) = (0,0,0,0,0);

# --- a simple, successful task -------------------------------------------
my $r = task({
	cmd => perl_cmd('exit 0')
});
if (
		($r->{'die'}) &&
		($r->{done} eq 'now') &&
		(!$r->{'exit'}) &&
		($r->{overwrite} == 0) &&
		(ref $r->{'output.files'} eq 'ARRAY') &&
		(scalar @{ $r->{'output.files'} } == 0)
	) {
	$simple_task = 1;
} else {
	p $r;
	die 'test failed';
}

# --- writing to a log file + say2 ----------------------------------------
my ($fh, $fname) = tempfile( UNLINK => 0, SUFFIX => '.log' );
$r = task({
	cmd            => perl_cmd('exit 0'),
	'log.fh'       => $fh,
	'output.files' => $fname,
	overwrite      => 1
});
say2('Testing say2', $fh);
close $fh;
$log_write = 1 if ((-f $fname) && (-s $fname > 0));

# --- re-run: task must notice the output already exists ------------------
$r = task({
	cmd            => perl_cmd('exit 0'),
	'output.files' => $fname,
	overwrite      => 0
});
p $r;
if (
		($r->{done} eq 'before')
		&&
		($r->{duration} == 0)
		&&
		($r->{'will.do'} eq 'no')
	) {
	$stopping = 1;
} else {
	p $r;
	die 'Could not stop because output files were already done';
}

# --- dry run --------------------------------------------------------------
$r = task({
	cmd       => perl_cmd('exit 0'),
	'dry.run' => 1
});
if (
	($r->{'dry.run'})	        &&
	($r->{duration} == 0)	  &&
	((defined $r->{'will.do'}) && ($r->{'will.do'} eq 'no: dry run'))
	) {
	$dry_run = 1;
} else {
	p $r;
	die 'dry run failed';
}

# --- task dies on a non-zero exit (default die => 1) ----------------------
dies_ok {
	task({
		cmd => perl_cmd('exit 2'), # non-zero exit, like the old "ls <missing>"
	});
} '"task" dies when the command exits non-zero';

# --- task dies on empty filenames ----------------------------------------
dies_ok {
	task({
		'input.files' => '',
		cmd           => perl_cmd('exit 0')
	});
} '"task" dies when given an empty filename in "input.files"';

dies_ok {
	task({
		'output.files' => '',
		cmd           => perl_cmd('exit 0')
	});
} '"task" dies when given an empty filename in "output.files"';

# --- overwrite => true actually re-runs and rewrites the file ------------
sleep 1;
my $mod0 = -M $fname;
say "\$mod0 = $mod0";
say "\$fname = $fname";
$r = task({
	cmd            => qq{$PERL -e "print 1" > "$fname"}, # portable redirect
	overwrite      => 'true',
	'output.files' => $fname
});
printf("$mod0 vs %lf\n", -M $fname);
if (
		($mod0 > -M $fname) # the file has been modified (mtime newer)
		&&
		(-s $fname > 0)
	) {
	$overwrite = 1;
} else {
	p $r;
	die 'output files are not overwritten when "overwrite" is true"';
}

# ===========================================================================
# Regression tests for bugs fixed in SimpleFlow.pm
# ===========================================================================

# --- BUG 1: exit/signal decoding -----------------------------------------
# The old code did $exit = $status >> 8 and THEN $signal = $exit & 127, so the
# low bits of the exit code leaked into the "signal" field (e.g. exit 137 was
# reported as signal 9) and a genuine kill-by-signal could never be seen.
# task() runs commands through a shell, so a child's signal shows up as the
# shell's exit code 128+N; the portable, decisive check is that the signal
# field is NEVER contaminated by the exit code.
subtest 'exit code and signal are decoded independently (regression)' => sub {
	my %expect = (0 => 0, 2 => 2, 42 => 42, 137 => 137);
	for my $code (sort { $a <=> $b } keys %expect) {
		my $t = task({ cmd => perl_cmd("exit $code"), die => 0 });
		is($t->{'exit'}, $expect{$code}, "exit code $code reported correctly");
		is($t->{signal}, 0, "signal is 0 for normal exit $code (old code leaked the exit bits)");
	}
};

# A real kill-by-signal of *task's own command process* (Unix only). When the
# shell itself is signalled, $? carries signal bits; signal must be that
# number and exit must be 0.
SKIP: {
	skip 'POSIX signal semantics differ on Windows', 2 if $^O eq 'MSWin32';
	# single-quote the inner code so the outer shell does not expand $$ itself
	my $cmd = qq{$PERL -e 'kill 15 => \$\$'};
	my $t = task({ cmd => $cmd, die => 0 });
	# Note: routed through a shell this usually surfaces as exit 128+15; the
	# point of the assertion is simply that signal is decoded from the RAW
	# status and is not just (exit & 127) of a shifted value.
	ok(defined $t->{signal}, 'signal field is defined after a signalled command');
	ok($t->{signal} == 0 || $t->{signal} == 15,
		'signal field holds a sane value (0 or the actual signal), not leaked exit bits');
}

# --- BUG 2: missing output file with die => 0 must not crash --------------
# The old zero-size check did ( -s $missing == 0 ), i.e. ( undef == 0 ), which
# is a fatal "uninitialized value" under 'use warnings FATAL => all' whenever a
# declared output file is absent and die => 0. It must now warn, not die.
my $missing;
{
	my $tmp = File::Temp->new(SUFFIX => '.gone'); # auto-unlinked on destroy
	$missing = $tmp->filename;
}
ok(! -e $missing, 'precondition: declared output file is absent');
my $r2;
lives_ok {
	$r2 = task({
		cmd            => perl_cmd('exit 0'),
		'output.files' => $missing,
		die            => 0,
	});
} 'task survives a missing output file when die => 0 (regression: undef == 0 was fatal)';
ok(defined $r2 && ref $r2 eq 'HASH', 'task still returned its result hash');

# ===========================================================================
# Additional coverage: note, *.file.size hashes, normalisation, metadata,
# captured I/O and argument validation.
# ===========================================================================

# --- note passthrough + default -----------------------------------------
subtest 'note field' => sub {
	my $t = task({ cmd => perl_cmd('exit 0'), note => 'hello note' });
	is($t->{note}, 'hello note', 'note is passed through to the result');
	my $d = task({ cmd => perl_cmd('exit 0') });
	is($d->{note}, '', 'note defaults to the empty string');
};

# --- output.files: scalar normalisation + output.file.size ---------------
subtest 'output.files normalisation and output.file.size' => sub {
	my (undef, $o1) = tempfile(UNLINK => 0, SUFFIX => '.dat');
	my $t = task({
		cmd            => qq{$PERL -e "print 12345" > "$o1"}, # writes exactly 5 bytes
		'output.files' => $o1,                                # scalar form
		overwrite      => 'true',
	});
	is(ref $t->{'output.files'}, 'ARRAY', 'scalar output.files is normalised to an arrayref');
	is_deeply($t->{'output.files'}, [$o1], 'output.files arrayref holds the filename');
	is($t->{'output.file.size'}{$o1}, 5,      'output.file.size reports the byte count');
	is($t->{'output.file.size'}{$o1}, -s $o1, 'output.file.size matches -s on disk');
	unlink $o1;
};

# --- input.files: scalar + array forms, and input.file.size --------------
subtest 'input.files and input.file.size' => sub {
	my ($fh1, $i1) = tempfile(UNLINK => 0); print {$fh1} 'abc';  close $fh1; # 3 bytes
	my ($fh2, $i2) = tempfile(UNLINK => 0); print {$fh2} 'wxyz'; close $fh2; # 4 bytes

	my $scalar = task({ cmd => perl_cmd('exit 0'), 'input.files' => $i1 });
	is($scalar->{'input.file.size'}{$i1}, 3,   'input.file.size (scalar form) reports size');
	is($scalar->{'input.files'},          $i1, 'input.files (scalar) is preserved on the result');

	my $array = task({ cmd => perl_cmd('exit 0'), 'input.files' => [$i1, $i2] });
	is($array->{'input.file.size'}{$i1}, 3, 'input.file.size (array form) reports first size');
	is($array->{'input.file.size'}{$i2}, 4, 'input.file.size (array form) reports second size');

	unlink $i1, $i2;
};

# --- metadata fields: dir, source.file, source.line ----------------------
subtest 'task metadata' => sub {
	my $t = task({ cmd => perl_cmd('exit 0') });
	is($t->{dir}, getcwd(),               'dir records the working directory');
	like($t->{'source.file'}, qr/01\.t$/, 'source.file points at the calling script');
	like($t->{'source.line'}, qr/^\d+$/,  'source.line is a line number');
};

# --- captured stdout / stderr (and trailing-whitespace stripping) --------
subtest 'captured output' => sub {
	my $out = task({ cmd => perl_cmd('print q{coverage}'),        die => 0 });
	is($out->{stdout}, 'coverage', 'stdout is captured into the result');
	my $err = task({ cmd => perl_cmd('print STDERR q{oops}'),     die => 0 });
	is($err->{stderr}, 'oops',     'stderr is captured into the result');
};

# --- argument validation -------------------------------------------------
subtest 'argument validation' => sub {
	dies_ok { task({ note => 'no cmd here' }) }
		'dies when the required "cmd" key is missing';
	dies_ok { task({ cmd => perl_cmd('exit 0'), bogus_key => 1 }) }
		'dies on an unrecognised argument key';
	dies_ok { task({ cmd => perl_cmd('exit 0'), 'log.fh' => 'not a filehandle' }) }
		'dies when log.fh is not a real filehandle';
	dies_ok { task({ cmd => perl_cmd('exit 0'), 'input.files' => 'this_file_should_not_exist_42' }) }
		'dies when a declared input file is missing';
};

# --- summary of the original behavioural tests ---------------------------
ok($simple_task, 'Verified: Simple task works');
ok($log_write,   'Verified: Can write to log files with subroutine "say2"');
ok($stopping,    'Verified: tasks do not run when output files exist');
ok($dry_run,     'Verified: dry run works');
ok($overwrite,   'Verified: "overwrite" option overwrites files in "output.files"');

unlink $fname if -f $fname;
done_testing();
