#!/usr/bin/env perl

#
# Regression tests for the defects CPAN testers found in 0.196.
#
# Block 1: report()'s flow diagram compared names as strings, so a file named
# through a symbolic link to a directory and the same file named through that
# directory's real path were two files, and no arrow joined the task that
# wrote one to the task that read the other. "dir" is recorded with getcwd(),
# which returns the real path, so naming a file relative to "dir" in one task
# and in full in another was enough. t/11.flow.t's last subtest failed this
# way on Haiku (where /tmp is a link to /boot/system/cache/tmp) and on a
# FreeBSD set up like macOS (where TMPDIR is under /var/folders, a link to
# /private/var/folders): reports ab327588-e398-11f1-9d95-ca6b7133da09 and
# f54b9114-e39c-11f1-aaa0-b0af0db2ccff. Here the link is made on purpose, so
# that the test does not depend on how the smoker's temporary directory is
# reached. It was confirmed to fail against 0.196's lib/SimpleFlow.pm, from
# git commit 829da03. The diagram is new in 0.196, so it cannot run against
# an older module.
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
use SimpleFlow qw(task report);

my $dir = tempdir(CLEANUP => 1);

sub slurp {
	my $file = shift;
	open my $fh, '<', $file or return '(unreadable)';
	binmode $fh;
	local $/;
	return scalar <$fh>;
}
# The boxes and arrows of an SVG that _flow_svg printed, read back with the
# patterns of flow() in t/11.flow.t, which says why there is no XML parser.
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
		$arrow{ ($from // q{?}) . q{>} . ($to // q{?}) } = $names;
	}
	return (\%box, \%arrow);
}

# --- 1. a name through a symbolic link is the same file as its real path ------
SKIP: {
	my $real = File::Spec->catdir($dir, 'real');
	my $link = File::Spec->catdir($dir, 'link');
	mkdir $real or die "cannot make \"$real\": $!";
	# symlink() dies where perl has none, and fails on MSWin32 without the
	# privilege to make one: there is no link to name the files through
	skip "cannot make a symbolic link here: $@$!", 1 unless eval { symlink $real, $link };
	subtest 'flow: a file named through a symbolic link is linked to its real path' => sub {
		my $trace_file = File::Spec->catfile($dir, 'trace.json');
		open my $trace, '>', $trace_file or die "cannot write \"$trace_file\": $!";
		my $write = q{open my $f, '>', $ARGV[0] or die; print {$f} 1};
		capture {
			# "dir" is the link, but the record holds getcwd(): the real path
			task(cmd => [$^X, '-e', $write, 'a'], dir => $link, 'output_file' => 'a',
				'trace_fh' => $trace, quiet => 1);
			task(cmd => [$^X, '-e', $write, File::Spec->catfile($link, 'b')],
				'input_file' => File::Spec->catfile($link, 'a'), 'output_file' => File::Spec->catfile($link, 'b'),
				'trace_fh' => $trace, quiet => 1);
			task(cmd => [$^X, '-e', '1'], dir => $link, 'input_file' => 'b', 'trace_fh' => $trace, quiet => 1);
		};
		close $trace;
		my $svg_file = File::Spec->catfile($dir, 'flow.svg');
		my $count;
		capture { $count = report(trace => $trace_file, svg => $svg_file) };
		is($count, 3, 'report() read the three tasks');
		my ($box, $arrow) = flow(slurp($svg_file));
		# the positive sentinel: the boxes were drawn, so a missing arrow below
		# means no arrow, not an unread file
		is_deeply([map { $box->{$_}{class} } 1 .. 3], [qw(done done done)], 'there is a box for each task, and each ran');
		is_deeply([sort keys %$arrow], ['1>2', '2>3'],
			'each task is linked to the next, though one names the file through the link and the other through '
			. 'its real path (until 0.196, no arrows)');
	};
}

done_testing();
