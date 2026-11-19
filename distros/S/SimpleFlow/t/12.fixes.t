#!/usr/bin/env perl

#
# Regression tests for the defects in report() found by an outside review of
# 0.196 before it shipped, in two groups.
#
# Blocks 1-4 are defects of 0.195, the release on CPAN, and use only the
# arguments it accepted (trace, html), so that they can be re-run against it:
# each was confirmed to fail against 0.195's lib/SimpleFlow.pm, from git
# commit f29822c.
#
# Blocks 5-8 test the flow diagram and the "svg" option, both new in 0.196,
# and cannot run against any released module. Blocks 5-7 were confirmed to
# fail against the 0.196 working copy before the fix; block 8 guards the
# fix itself, and passed before it, when report() opened its files in place.
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
use JSON::PP ();
use SimpleFlow 'report';

my $dir = tempdir(CLEANUP => 1);
my $n = 0;
sub fresh_path { return File::Spec->catfile($dir, 'f' . ++$n) }

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or return '(unreadable)';
	binmode $fh;
	local $/;
	return scalar <$fh>;
}

sub write_trace {
	my $trace = fresh_path();
	open my $fh, '>', $trace or die "cannot write \"$trace\": $!";
	print {$fh} JSON::PP->new->utf8->canonical->encode($_), "\n" foreach @_;
	close $fh;
	return $trace;
}

# report() over the records, with any more arguments; returns the error, '' if
# there was none.
sub run_report {
	my ($records, @more) = @_;
	my $trace = write_trace(@$records);
	my $error;
	capture { eval { report(trace => $trace, @more) }; $error = $@ };
	return $error;
}

sub files_in {
	my $d = shift;
	opendir my $dh, $d or die "cannot read \"$d\": $!";
	return sort grep { ($_ ne '.') && ($_ ne '..') } readdir $dh;
}

# ---- 1-4: defects of 0.195 -------------------------------------------------

subtest '1. a quick last task\'s timeline bar stays inside its lane' => sub {
	# The bar has a minimum width of 0.5%, so 0.195 drew a quick task that
	# started in the last half percent of the run past the end of the lane:
	# this one at margin-left 99.99% and width 0.50%.
	my $html = fresh_path() . '.html';
	my $error = run_report([
		{ 'will.do' => 'done', cmd => 'slow',  'start.time' => 1000,     duration => 10 },
		{ 'will.do' => 'done', cmd => 'quick', 'start.time' => 1009.999, duration => 0.001 },
	], html => $html);
	is($error, '', 'report() returned');
	my @bars;
	my $page = slurp($html);
	while ($page =~ /<div class="bar \w+" style="margin-left:([\d.]+)%;width:([\d.]+)%">/g) {
		push @bars, [$1, $2];
	}
	is(scalar @bars, 2, 'the positive half: both tasks have a bar');
	foreach my $i (0 .. $#bars) {
		my ($left, $width) = @{ $bars[$i] };
		cmp_ok($left + $width, '<=', 100 + 1e-9, "bar " . ($i + 1) . " ends inside the lane (0.195: 99.99% + 0.50%)");
	}
	cmp_ok($bars[1][1], '>=', 0.5, 'the quick task\'s bar still has the minimum width');
	cmp_ok(abs($bars[1][0] + $bars[1][1] - 100), '<', 1e-9, 'and still ends where the run did');
};

subtest '2. the summary counts every task, whatever its status' => sub {
	# A status other than the four task() writes -- from a hand-made trace, or
	# none at all -- was counted, and shown in the table, but left out of the
	# summary, so 0.195 said "3 tasks: 1 done, 0 skipped, 0 failed".
	my $html = fresh_path() . '.html';
	my $error = run_report([
		{ 'will.do' => 'done', cmd => 'a' },
		{ 'will.do' => 'yes',  cmd => 'b' },
		{ cmd => 'c' },
	], html => $html);
	is($error, '', 'report() returned');
	my ($summary) = slurp($html) =~ m{<p class="summary">([^<]*)</p>};
	ok(defined $summary, 'the positive half: the page has a summary');
	$summary //= '';
	my ($total, $counts) = $summary =~ /\A(\d+) tasks: (.*)\z/;
	is($total, 3, 'of three tasks');
	my $sum = 0;
	$sum += $_ foreach ($counts // '') =~ /(\d+) /g;
	is($sum, 3, "whose counts add up to three (0.195: \"3 tasks: 1 done, 0 skipped, 0 failed\"): \"$summary\"");
	like($summary, qr/\b1 yes\b/, 'an unknown status is counted under its own name');
	like($summary, qr/\b1 unknown\b/, 'and a record with none, as "unknown", as the table shows it');
	like($summary, qr/\A3 tasks: 1 done, 0 skipped, 0 failed, /, 'after the known statuses, as before');
};

subtest '3. one task is "1 task", and one dry run "1 dry run"' => sub {
	# 0.195 made both plural whatever the count: "1 tasks: 0 done, 0 skipped,
	# 0 failed, 1 dry runs".
	my $html = fresh_path() . '.html';
	my $error = run_report([{ 'will.do' => 'no: dry run', cmd => 'a' }], html => $html);
	is($error, '', 'report() returned');
	my ($summary) = slurp($html) =~ m{<p class="summary">([^<]*)</p>};
	ok(defined $summary, 'the positive half: the page has a summary');
	is($summary, '1 task: 0 done, 0 skipped, 0 failed, 1 dry run',
		'singular for one (0.195: "1 tasks: 0 done, 0 skipped, 0 failed, 1 dry runs")');
	$error = run_report([({ 'will.do' => 'no: dry run', cmd => 'a' }) x 2], html => $html);
	is($error, '', 'report() returned for two');
	($summary) = slurp($html) =~ m{<p class="summary">([^<]*)</p>};
	is($summary, '2 tasks: 0 done, 0 skipped, 0 failed, 2 dry runs', 'and plural for two, as before');
};

subtest '4. a task of any status that ran has a visible timeline bar' => sub {
	# Only ".bar.done" and ".bar.failed" had a background, so 0.195 drew the
	# bar of any other status -- "yes", from a hand-made trace -- transparent.
	my $html = fresh_path() . '.html';
	my $error = run_report([{ 'will.do' => 'yes', cmd => 'a', 'start.time' => 1000, duration => 1 }], html => $html);
	is($error, '', 'report() returned');
	my $page = slurp($html);
	like($page, qr/<div class="bar other" style="/, 'the positive half: the task has a bar, of class "other"');
	like($page, qr/^\.bar \{[^}]*\bbackground:/m, 'and every bar has a background unless its class sets another (0.195: none)');
};

# ---- 5-8: the flow diagram and "svg", new in 0.196 -------------------------

my $d1 = File::Spec->catdir($dir, 'd1');

subtest '5. white space at the ends of a command is not part of its label' => sub {
	# The working copy of 0.196 made each run of white space one space, the
	# ends included, so "\n  echo hi\n" was labeled " echo hi ": indented, and
	# two characters short of the 33 a label may show.
	my $svg = fresh_path() . '.svg';
	my $error = run_report([{ 'will.do' => 'done', cmd => "\n  echo   hi\n" }], svg => $svg);
	is($error, '', 'report() returned');
	my $text = slurp($svg);
	like($text, qr{<text class="sf-head"[^>]*>#1 done</text>}, 'the positive half: the box is there');
	like($text, qr{<text x="[\d.]+" y="[\d.]+">echo hi</text>}, 'and its label is "echo hi" (before: " echo hi ")');
};

subtest '6. an arrow\'s tooltip names each file once' => sub {
	# A task that named a file twice, or in two ways, had it twice in the
	# tooltip of the arrow to it: "a\na\n./a" in the working copy of 0.196.
	my $svg = fresh_path() . '.svg';
	my $error = run_report([
		{ 'will.do' => 'done', cmd => 'make', dir => $d1, output_files => ['a', 'b'] },
		{ 'will.do' => 'done', cmd => 'read', dir => $d1, input_files => ['a', 'a', File::Spec->catfile(File::Spec->curdir, 'a'), 'b'] },
	], svg => $svg);
	is($error, '', 'report() returned');
	my @titles = slurp($svg) =~ m{<path class="sf-edge" [^>]*><title>([^<]*)</title></path>}g;
	is(scalar @titles, 1, 'the positive half: there is one arrow');
	is($titles[0], "a\nb", 'and it names "a", as first written, and "b", once each (before: "a\na\n./a\nb")');
};

subtest '7. a page and diagram are written together, or neither is' => sub {
	# The working copy of 0.196 wrote the page, then failed to write the
	# diagram and died, leaving a new page beside an old diagram, or a new
	# page where none was asked to be kept.
	my $out = File::Spec->catdir($dir, 'out5');
	mkdir $out or die "cannot make \"$out\": $!";
	my $html = File::Spec->catfile($out, 'report.html');
	my $nowhere = File::Spec->catfile($dir, 'no-such-dir', 'flow.svg');
	my @records = ({ 'will.do' => 'done', cmd => 'new task' });

	my $error = run_report(\@records, html => $html, svg => $nowhere);
	like($error, qr/cannot write the diagram "\Q$nowhere\E"/, 'report() died for the diagram');
	ok(not(-e $html), 'and wrote no page (before: it wrote one)');

	open my $fh, '>', $html or die "cannot write \"$html\": $!";
	print {$fh} 'the old page';
	close $fh;
	$error = run_report(\@records, html => $html, svg => $nowhere);
	like($error, qr/cannot write the diagram "\Q$nowhere\E"/, 'run again over an old page, report() died for the diagram');
	is(slurp($html), 'the old page', 'and the old page is as it was (before: replaced)');
	is_deeply([files_in($out)], ['report.html'], 'with nothing left beside it');

	my $svg = File::Spec->catfile($out, 'flow.svg');
	$error = run_report(\@records, html => $html, svg => $svg);
	is($error, '', 'given a diagram it can write, report() returned');
	like(slurp($html), qr{<code>new task</code>}, 'and replaced the page');
	like(slurp($svg), qr{<svg }, 'and wrote the diagram');
	is_deeply([files_in($out)], ['flow.svg', 'report.html'], 'leaving only the two');
};

subtest '8. a page gets the permissions open() would have given it' => sub {
	# Each file is written under a File::Temp name and renamed into place;
	# File::Temp makes its files 0600, which would hide a page from a web
	# server, or another user, that could read the one before. Not on MSWin32,
	# whose permissions are not these bits.
	plan skip_all => 'MSWin32 has no POSIX permission bits' if $^O eq 'MSWin32';
	my $out = File::Spec->catdir($dir, 'out6');
	mkdir $out or die "cannot make \"$out\": $!";
	my $html = File::Spec->catfile($out, 'report.html');
	my @records = ({ 'will.do' => 'done', cmd => 'a' });
	my $old_umask = umask 022;
	my $error = run_report(\@records, html => $html);
	is($error, '', 'report() returned');
	ok(-e $html, 'the positive half: it wrote the page');
	is(sprintf('%04o', (stat $html)[2] & 07777), '0644', 'a new page is 0666 less the umask, 022');
	chmod 0640, $html or die "cannot chmod \"$html\": $!";
	$error = run_report(\@records, html => $html);
	is($error, '', 'report() returned again');
	is(sprintf('%04o', (stat $html)[2] & 07777), '0640', 'and a page it replaced keeps the mode it had');
	umask $old_umask;
};

done_testing();
