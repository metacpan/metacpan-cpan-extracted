#!/usr/bin/perl -w -I../lib

our $debug;
BEGIN {
$debug = 0;
}

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Proc::JobQueue::Testing;
use Object::Dependency;

use Test::More;
use Proc::JobQueue::BackgroundQueue;
use aliased 'Proc::JobQueue::Sort';
use aliased 'Proc::JobQueue::Move';
use aliased 'Proc::JobQueue::Sequence';
use aliased 'Proc::JobQueue::Command';
use Sys::Hostname;
use File::Temp qw(tempdir);
use Time::HiRes qw(time);
use File::Slurp;
use Proc::JobQueue::EventQueue;
use Proc::JobQueue::DependencyJob;
use Proc::JobQueue::DependencyTask;
use Proc::JobQueue::RemoteDependencyJob;
use IO::Event 'emulate_Event';

my $tmpdir = tempdir(CLEANUP => 1);

#if ($debug) {
#	open(STDOUT, "| tee $tmpdir/output")
#		or die "open STDOUT | tee: $!";
#} else {
#	open(STDOUT, ">$tmpdir/output")
#		or die "redirect STDOUT to $tmpdir/output: $!";
#}
#select(STDOUT);
#$| = 1;
#open(STDERR, ">&STDOUT") or die "dup STDOUT: $!";
#select(STDERR);
#$| = 1;
#
#my $shdebug = $debug ? "set -x; " : "";

plan tests => 28;

my $graph = Object::Dependency->new();

my $queue = Proc::JobQueue::EventQueue->new(
	dependency_graph => $graph,
	hold_all => 1,
);

$queue->addhost('localhost', jobs_per_host => 2);

my $timer;
sub reset_bomb
{
	$timer->cancel if $timer;
        $timer = IO::Event->timer(
                after   => 10,
                cb      => sub {
                        ok(0, "bomb timer went off, something failed");
                        exit 0;
                },
        );
}


# 
# We will construct a pyramid of jobs.  
#
# Layer	Mult	Desc				handler
#  1	1	generate random numbers		DependencyJob
#  2	1	write out numbers		DependencyTask
#  3	3	Combine random numbers		DependencyJob
#  4	2	Sort combined files		RemoteDependencyJob
#
# We will place the jobs into the queue in reverse order
#

my $nrandom = 1000;
my @outputs = ("A");
my %inputs;


my @final_jobs;
my @new_outputs;
for my $out (@outputs) {
	my @in = ("$out.1", "$out.2");
	push(@new_outputs, @in);
	my $job;
	$job = Proc::JobQueue::RemoteDependencyJob->create( 
		prefix			=> '# ',
		preload			=> [qw(File::Slurp)], 
		dependency_graph	=> $graph,
		host			=> 'localhost',

		chdir			=> $tmpdir,
		data			=> {
			output	=> $out,
			inputs	=> \@in,
		},
		preload			=> [qw(File::Slurp)],
		desc			=> "combine and sort -> $out",
		when_done		=> sub {
			reset_bomb();
			write_file("$tmpdir/$out", join("\n", @_) . "\n");
			ok(1, "wrote $out");
			$job->finished(0);
		},
		on_start		=> sub {
			reset_bomb();
		},
		eval            	=> <<'END_REMOTEJOB',
			
			my ($data) = @_;
			print "reading $data->{inputs}[0]\n";
			print "reading $data->{inputs}[1]\n";
			my @in1 = split("\n", read_file($data->{inputs}[0]));
			my @in2 = split("\n", read_file($data->{inputs}[1]));
			return (sort { $a <=> $b } @in1, @in2);
			
END_REMOTEJOB
	);
	$inputs{$_} = $job for @in;
	push(@final_jobs, $job);
}
@outputs = @new_outputs;
is(scalar(@outputs), 2, "num outputs");

my $finish = Proc::JobQueue::DependencyTask->new(
	desc	=> 'unloop',
	func	=> sub {
		reset_bomb();
		ok($queue->alldone, "queue empty");
		IO::Event::unloop_all();
		return 'done';
	},
);
$graph->add($finish, $_) for @final_jobs;

undef @new_outputs;
for my $out (@outputs) {
	my @in = ("$out.A", "$out.B", "$out.C");
	push(@new_outputs, @in);
	my $job = Proc::JobQueue::DependencyJob->new($graph, 
		sub {
			my $data = '';
			for my $input (@in) {
				$data .= read_file("$tmpdir/$input");
			}
			write_file("$tmpdir/$out", $data);
			reset_bomb();
			ok(1, "wrote $out combining @in");
			return 'all-done';
		},
		desc	=> "read @in -> $out",
	);
	$inputs{$_} = $job for @in;
	$graph->add($inputs{$out}, $job);
}
@outputs = @new_outputs;
is(scalar(@outputs), 6, "num outputs");

my %membuf;

undef @new_outputs;
for my $out (@outputs) {
	my $in = ("$out.membuf");
	push(@new_outputs, $in);
	my $job = Proc::JobQueue::DependencyTask->new(
		desc	=> "write $out.membuf -> $out",
		func	=> sub {
			write_file("$tmpdir/$out", join("\n", @{$membuf{$in}}) . "\n");
			reset_bomb();
			ok(1, "wrote $out");
			return 'done';
		},
	);
	$inputs{$in} = $job;
	$graph->add($inputs{$out}, $job);
}
@outputs = @new_outputs;
is(scalar(@outputs), 6, "num outputs");


for my $out (@outputs) {
	my $job;
	$job = Proc::JobQueue::DependencyJob->new($graph, 
		sub {
			my $timer;
			$timer = IO::Event->timer(
				after => 0.01,
				cb => sub {
					my @r;
					for my $i (1..$nrandom) {
						push(@r, rand(1000));
					}
					$membuf{$out} = \@r;
					$timer->cancel();
					$job->finished(0);
					reset_bomb();
					ok(1, "job for $out finished");
				},
			);
			ok(1, "set up timer for $out");
			return 'all-keep';
		},
		desc	=> "set up timer to write generate membuf $out",
	);
	$graph->add($inputs{$out}, $job);
}
is(scalar(@outputs), 6, "num outputs");

$queue->hold(0);

$queue->startmore();

reset_bomb();
IO::Event::loop();
reset_bomb();

ok(-e "$tmpdir/A", "A exists");
my @nums = read_file("$tmpdir/A");
is(scalar(@nums), scalar(@outputs)*$nrandom, "count of numbers");

