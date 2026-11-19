#!/usr/bin/env perl

#
# Tests for the flow diagram report() draws, added in 0.196: a box for each
# task of a trace, and an arrow from a task to each later one that reads what
# it wrote, written to the "svg" file and put in the HTML page. Nothing here
# can run against an older module, which had no "svg".
#
# Most traces are written by hand, so that which task declared which name is
# exact; each name's directory is an absolute path made by File::Spec from a
# temporary directory, so that the same trace means the same thing on MSWin32.
# There is no XML parser among the prereqs, so flow() below reads the boxes and
# arrows back with patterns written for exactly what _flow_svg prints.
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
use SimpleFlow qw(task report);

my $dir = tempdir(CLEANUP => 1);
my $n = 0;
sub fresh_path { return File::Spec->catfile($dir, 'f' . ++$n) }
my $d1 = File::Spec->catdir($dir, 'd1');
my $d2 = File::Spec->catdir($dir, 'd2');

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or return '(unreadable)';
	binmode $fh;
	local $/;
	return scalar <$fh>;
}

# Write the records to a trace, run report() over it, and return what it
# returned, the SVG as characters, and the error.
sub run_report {
	my ($records, @more) = @_;
	my $trace = fresh_path();
	open my $fh, '>', $trace or die;
	print {$fh} JSON::PP->new->utf8->canonical->encode($_), "\n" foreach @$records;
	close $fh;
	my $svg = fresh_path() . '.svg';
	my ($count, $error);
	capture { $count = eval { report(trace => $trace, svg => $svg, @more) }; $error = $@ };
	my $text = slurp($svg);
	utf8::decode($text);
	return ($count, $text, $error);
}

# The diagram's boxes, numbered as the tasks are, and its arrows, as
# "from>to" => the names in the arrow's tooltip. An arrow is matched to a box
# by where it starts and ends: on the middle of the box's right and left edges.
sub flow {
	my $svg = shift;
	my (%box, %arrow);
	while ($svg =~ m{<g class="sf-task sf-(\w+)"><title>\#(\d+) [^<]*</title><rect x="([\d.]+)" y="([\d.]+)" width="(\d+)" height="(\d+)"}g) {
		$box{$2} = { class => $1, x => $3, y => $4, w => $5, h => $6 };
	}
	while ($svg =~ m{<path class="sf-edge" d="M ([\d.]+) ([\d.]+) (.*?)" marker-end="url\(\#sf-arrow\)"><title>([^<]*)</title></path>}g) {
		my ($x1, $y1, $rest, $names) = ($1, $2, $3, $4);
		my ($x2, $y2) = $rest =~ /([\d.]+) ([\d.]+)\z/;
		my ($from) = grep { ($box{$_}{x} + $box{$_}{w} == $x1) && ($box{$_}{y} + $box{$_}{h} / 2 == $y1) } keys %box;
		my ($to)   = grep { ($box{$_}{x} == $x2) && ($box{$_}{y} + $box{$_}{h} / 2 == $y2) } keys %box;
		$arrow{ ($from // '?') . '>' . ($to // '?') } = $names;
	}
	return (\%box, \%arrow);
}

sub rec { return { 'will.do' => 'done', cmd => 'c', @_ } }

subtest 'flow: an arrow joins a task to the one reading its output, by path' => sub {
	my ($count, $svg, $error) = run_report([
		rec(cmd => 'make a', dir => $d1, output_files => ['a.txt']),
		rec(cmd => 'read ./a', dir => $d1, input_files => ['./a.txt'], output_files => ['b.txt']),
		rec(cmd => 'read a elsewhere', dir => $d2, input_files => ['a.txt']),
		rec(cmd => 'read b by its full name', dir => $d2, input_files => [File::Spec->catfile($d1, 'b.txt')]),
	]);
	is($error, '', 'report() returned');
	is($count, 4, 'and read four tasks');
	my ($box, $arrow) = flow($svg);
	is(scalar keys %$box, 4, 'the positive half: there is a box for each task');
	is_deeply($arrow, { '1>2' => './a.txt', '2>4' => File::Spec->catfile($d1, 'b.txt') },
		'"./a.txt" is the "a.txt" made in the same directory, and a full name is matched too, '
		. 'but not the same name in another directory');
	is($box->{1}{x}, $box->{3}{x}, 'a task that reads nothing made here starts in the first column');
	cmp_ok($box->{2}{x}, '>', $box->{1}{x}, 'and one that does is to the right of its source');
};

subtest 'flow: a file in an output directory comes from the task that made the directory' => sub {
	my (undef, $svg, $error) = run_report([
		rec(dir => $d1, output_dirs => ['samples']),
		rec(dir => $d1, input_files => [File::Spec->catfile('samples', 's1.fq')]),
		rec(dir => $d1, input_dirs => ['samples']),
	]);
	is($error, '', 'report() returned');
	my (undef, $arrow) = flow($svg);
	is_deeply([sort keys %$arrow], ['1>2', '1>3'], 'a file in it, and the directory itself, are both linked to it');
};

subtest 'flow: the most recent earlier task is the source, and never the task itself' => sub {
	my (undef, $svg, $error) = run_report([
		rec(dir => $d1, output_files => ['x']),
		rec(dir => $d1, output_files => ['x']),
		rec(dir => $d1, input_files => ['x'], output_files => ['x']), # rewrites its input
		rec(dir => $d1, input_files => ['x', 'later']),
		rec(dir => $d1, output_files => ['later']),
	]);
	is($error, '', 'report() returned');
	my (undef, $arrow) = flow($svg);
	is_deeply($arrow, { '2>3' => 'x', '3>4' => 'x' },
		'each reader is linked to the last writer before it, a rewriter to the one before it, and nothing to a later one');
};

subtest 'flow: a pipeline run twice onto one trace is two flows, not one' => sub {
	my @run = (rec(dir => $d1, output_files => ['a']), rec(dir => $d1, input_files => ['a'], 'will.do' => 'no'));
	my (undef, $svg, $error) = run_report([@run, @run]);
	is($error, '', 'report() returned');
	my ($box, $arrow) = flow($svg);
	is_deeply([sort keys %$arrow], ['1>2', '3>4'], 'the second run is linked within itself');
	is($box->{2}{class}, 'skipped', 'and a skipped task is drawn as one');
};

subtest 'flow: a trace with no "dir", as before 0.19, compares the names as they are' => sub {
	my (undef, $svg, $error) = run_report([
		rec(output_files => ['a']), rec(input_files => ['a']), rec(input_files => ['./a']),
	]);
	is($error, '', 'report() returned');
	my (undef, $arrow) = flow($svg);
	ok(exists $arrow->{'1>2'}, 'the same name is linked');
	ok(exists $arrow->{'1>3'}, 'and so is the same name written another way, once canonical');
};

subtest 'flow: an arrow that skips a column goes around the boxes in it' => sub {
	my (undef, $svg, $error) = run_report([
		rec(dir => $d1, output_files => ['a']),
		rec(dir => $d1, input_files => ['a'], output_files => ['b']),
		rec(dir => $d1, input_files => ['a', 'b']),
	]);
	is($error, '', 'report() returned');
	my ($box, $arrow) = flow($svg);
	is_deeply([sort keys %$arrow], ['1>2', '1>3', '2>3'], 'the arrows are there');
	ok(($box->{1}{x} < $box->{2}{x}) && ($box->{2}{x} < $box->{3}{x}), 'and the tasks are in three columns');
	my $right = $box->{1}{x} + $box->{1}{w};
	my ($long) = $svg =~ m{<path class="sf-edge" d="M \Q$right\E [^"]*? L ([^"]*)"};
	ok(defined $long, 'the arrow from the first to the third runs straight through the middle column');
	my ($through) = $svg =~ m{<path class="sf-edge" d="M [\d.]+ [\d.]+ C [\d.]+ [\d.]+, [\d.]+ [\d.]+, [\d.]+ ([\d.]+) L };
	isnt($through, $box->{2}{y} + $box->{2}{h} / 2, 'on a row of its own, not through the box there');
};

subtest 'flow: each status is drawn in its own color' => sub {
	my (undef, $svg, $error) = run_report([
		rec('will.do' => 'done'), rec('will.do' => 'no'), rec('will.do' => 'FAILED'),
		rec('will.do' => 'no: dry run'), rec('will.do' => 'yes'), { cmd => 'none' },
	]);
	is($error, '', 'report() returned');
	my ($box) = flow($svg);
	is_deeply([map { $box->{$_}{class} } 1 .. 6], ['done', 'skipped', 'failed', 'dry', 'other', 'other'],
		'done, skipped, FAILED and dry run have classes; anything else is "other"');
	like($svg, qr/<title>#5 yes\n/, 'an unknown status is shown as it is');
	like($svg, qr/\@media \(prefers-color-scheme: dark\)/, 'and the colors follow a dark setting');
};

subtest 'flow: labels are clipped and escaped, and the tooltip has the rest' => sub {
	my $long = 'x' x 40;
	my (undef, $svg, $error) = run_report([
		rec(cmd => $long, note => 'the note', dir => $d1, input_files => ['in'], output_dirs => ['out']),
		rec(cmd => qq{a <b> & "c"\x01\tline\ntwo \x{263a}}),
	]);
	is($error, '', 'report() returned');
	like($svg, qr{<text x="[\d.]+" y="[\d.]+">${\ ('x' x 32)}\x{2026}</text>}, 'a long command is clipped to 33 characters, the last an ellipsis');
	like($svg, qr{<title>#1 done\n$long\nthe note\ninputs: in\noutputs: out</title>}, 'and the tooltip has it whole, with the note and the names');
	like($svg, qr{<text x="[\d.]+" y="[\d.]+">a &lt;b&gt; &amp; &quot;c&quot;\x{fffd} line two \x{263a}</text>},
		'markup is escaped, white space is one space, and a control character XML cannot hold is replaced');
	unlike($svg, qr/[\x00-\x08]/, 'so none is written raw');
	like($svg, qr/\A<\?xml version="1\.0" encoding="UTF-8"\?>\n<svg xmlns="http:\/\/www\.w3\.org\/2000\/svg"/, 'the file is a standalone SVG image');
};

subtest 'flow: the page shows the diagram only when a task uses another one\'s output' => sub {
	my $html = fresh_path() . '.html';
	my $trace = fresh_path();
	open my $fh, '>', $trace or die;
	print {$fh} JSON::PP->new->canonical->encode($_), "\n"
		foreach rec(dir => $d1, output_files => ['a']), rec(dir => $d1, input_files => ['a']);
	close $fh;
	my $count;
	capture { $count = report(trace => $trace, html => $html) };
	is($count, 2, 'report() read two tasks');
	my $page = slurp($html);
	like($page, qr{<h2>Flow</h2>\n<div class="flow">\n<svg xmlns=.*</svg>\n</div>}s, 'the page has the diagram');
	unlike($page, qr/<\?xml/, 'inline, without the XML declaration of the file');

	open $fh, '>', $trace or die;
	print {$fh} JSON::PP->new->canonical->encode($_), "\n" foreach rec(cmd => 'alone'), rec(cmd => 'apart');
	close $fh;
	capture { report(trace => $trace, html => $html) };
	$page = slurp($html);
	like($page, qr{<code>apart</code>}, 'the positive half: the page was rewritten');
	unlike($page, qr/<svg|<h2>Flow/, 'and with no arrows to draw, it has no diagram');
};

subtest 'flow: "svg" alone writes the diagram and no page; an empty trace is an empty diagram' => sub {
	my ($count, $svg, $error) = run_report([]);
	is($error, '', 'report() returned without "html"');
	is($count, 0, 'having read no tasks');
	like($svg, qr{<svg [^>]*width="24" height="24"[^>]*>.*</svg>\n\z}s, 'and wrote an empty diagram, its margins only');
};

subtest 'flow: the ways report() refuses "svg", and a trace\'s names' => sub {
	my $trace = fresh_path();
	open my $fh, '>', $trace or die;
	print {$fh} qq{{"cmd":"a","will.do":"done"}\n};
	close $fh;
	my $nowhere = File::Spec->catfile($dir, 'no-such-dir', 'flow.svg');
	foreach my $case (
		[[trace => $trace], qr/report\(\) needs "html" or "svg", a file name to write/],
		[[trace => $trace, svg => []], qr/report\(\) needs "svg", a file name/],
		[[trace => $trace, svg => ''], qr/report\(\) needs "svg", a file name/],
		[[trace => $trace, html => fresh_path(), svg => {}], qr/report\(\) needs "svg", a file name/],
		[[trace => $trace, svg => $nowhere], qr/cannot write the diagram "\Q$nowhere\E"/],
	) {
		my ($args, $expect) = @$case;
		my $error;
		capture { eval { report(@$args) }; $error = $@ };
		like($error, $expect, "refused: $expect");
	}
	foreach my $case (
		[{ input_files => 'a' },        qr/its "input_files" is not a list of names/],
		[{ output_files => [undef] },   qr/its "output_files" is not a list of names/],
		[{ input_dirs => [['a']] },     qr/its "input_dirs" is not a list of names/],
		[{ output_dirs => [''] },       qr/its "output_dirs" is not a list of names/],
		[{ dir => ['a'] },              qr/its "dir" is not a single value/],
	) {
		my ($fields, $expect) = @$case;
		my (undef, undef, $error) = run_report([rec(%$fields)]);
		like($error, qr/line 1 of the trace "[^"]+" is not a task's record: $expect/, "refused: $expect");
	}
};

subtest 'flow: from a trace that task() wrote' => sub {
	my $trace_file = fresh_path();
	open my $trace, '>', $trace_file or die;
	my $sub = File::Spec->catdir($dir, 'run');
	mkdir $sub or die;
	my $write = q{open my $f, '>', $ARGV[0] or die; print {$f} 1};
	capture {
		task(cmd => [$^X, '-e', $write, 'a'], dir => $sub, 'output_file' => 'a', 'trace_fh' => $trace, quiet => 1);
		task(cmd => [$^X, '-e', $write, File::Spec->catfile($sub, 'b')], 'input_file' => File::Spec->catfile($sub, 'a'),
			'output_file' => File::Spec->catfile($sub, 'b'), 'trace_fh' => $trace, quiet => 1);
		task(cmd => [$^X, '-e', '1'], dir => $sub, 'input_file' => 'b', 'trace_fh' => $trace, quiet => 1);
	};
	close $trace;
	my $svg_file = fresh_path() . '.svg';
	my $count;
	capture { $count = report(trace => $trace_file, svg => $svg_file) };
	is($count, 3, 'report() read three tasks');
	my ($box, $arrow) = flow(slurp($svg_file));
	is_deeply([sort keys %$arrow], ['1>2', '2>3'],
		'a name relative to "dir" and the same file named in full are linked, both ways');
	is_deeply([map { $box->{$_}{class} } 1 .. 3], ['done', 'done', 'done'], 'and every step ran');
};

done_testing();
