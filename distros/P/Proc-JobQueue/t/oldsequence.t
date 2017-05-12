#!/usr/bin/perl -w -I../lib

our $debug;
BEGIN {
$debug = 0;
}

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Proc::JobQueue::Testing;

use Test::More;
use Proc::JobQueue::BackgroundQueue;
use aliased 'Proc::JobQueue::Sort';
use aliased 'Proc::JobQueue::Move';
use aliased 'Proc::JobQueue::OldSequence';
use aliased 'Proc::JobQueue::Command';
use Sys::Hostname;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);
use File::Slurp;


my $generate_files_time = 0.01;
my $sleeptime = 0.01;
my $nfiles = 5;
my $nsteps = 4;
my $dump_output = 1;

my $tmpdir = tempdir(CLEANUP => 1);

if ($debug) {
	open(STDOUT, "| tee $tmpdir/output")
		or die "open STDOUT | tee: $!";
} else {
	open(STDOUT, ">$tmpdir/output")
		or die "redirect STDOUT to $tmpdir/output: $!";
}
select(STDOUT);
$| = 1;
open(STDERR, ">&STDOUT") or die "dup STDOUT: $!";
select(STDERR);
$| = 1;

my $shdebug = $debug ? "set -x; " : "";

plan tests => $nfiles + 1;

my $queue = new Proc::JobQueue::BackgroundQueue (sleeptime => $sleeptime);
$queue->addhost('localhost', jobs_per_host => 8);

for my $n (1..$nfiles) {
	open my $fd, ">", "$tmpdir/step0A.file$n" or die;
	my $t = time;
	my $count;
	while (time - $t < $generate_files_time || ! $count) {
		my $r = rand();
		print $fd "f$n $r\n" x 400
			or die;
		$count++;
	}
	close($fd)
		or die;
	print "# $count items in bucket $n\n";
}

diag "done making input data";

for my $n (1..$nfiles) {
	my @seq;
	for my $s (0..($nsteps-1)) {
		push(@seq, Sort->new({}, {}, "$tmpdir/step${s}B.file$n", "$tmpdir/step${s}A.file$n"));
		push(@seq, Command->new("mv $tmpdir/step${s}B.file$n $tmpdir/step${s}C.file$n"));
		my $ns = $s+1;
		push(@seq, Move->new({}, {}, "$tmpdir/step${s}C.file$n", "$tmpdir/step${ns}A.file$n", 'localhost'));
	}
	$queue->add(OldSequence->new({}, {}, @seq));
}


$queue->finish();

my $combined = read_file("$tmpdir/output");

my @match = ($combined =~ /^(\+ .*)$/mg);

for my $n (1..$nfiles) {
	ok(-e "$tmpdir/step${nsteps}A.file$n", "file $tmpdir/step${nsteps}A.file$n exists");
}

is(scalar(@match), $nfiles * $nsteps * 3, "count of commands run");

$dump_output = 0;

END {
	if ($dump_output) {
		my $out = read_file("$tmpdir/output");
		diag $out;
	} else {
		diag "clean finish";
	}
}
	

