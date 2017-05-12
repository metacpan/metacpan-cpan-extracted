#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ProgressBar::Stack;
use Time::HiRes;
use List::Util qw(sum reduce);

plan tests => 22;

# testrenderer to check values
my @resultpercent = ();
my $lastmessage = "";

sub testrenderer($$) {
	my $value = shift;
	my $message = shift;
	if($message eq $lastmessage && scalar @resultpercent) {
		push @resultpercent, $value;
	} else {
		push @resultpercent, "$value|$message";
		$lastmessage = $message;
	}
}

# First test testsuite
@resultpercent = ();
testrenderer(0, "test");
testrenderer(50, "test");
testrenderer(100, "test2");
is_deeply(\@resultpercent, ["0|test",50,"100|test2"], "testsuite test");

# simple
@resultpercent = ();
init_progress(message => "Simple", renderer => \&testrenderer, forceupdatevalue => 0);
update_progress 20;
update_progress 60;
update_progress 100;
is_deeply(\@resultpercent,["0|Simple",20,60,100], "simple");

# loop
@resultpercent = ();
init_progress(message => "loop", renderer => \&testrenderer, forceupdatevalue => 0);
for_progress {} 1..5;
is_deeply(\@resultpercent,["0|loop",20,40,60,80,100], "loop");

# check whether reduce_progress works the same way as reduce
init_progress(minupdatetime => 1, renderer => sub {}, forceupdatevalue => 2, message => "Calculating sum of cubes");
is ((reduce_progress {$a + $b*$b*$b} 1..100000),(reduce {$a + $b*$b*$b} 1..100000), "reduce");

# sub_progress
@resultpercent = ();
init_progress(message => "Subprogress", renderer => \&testrenderer, forceupdatevalue => 0);
sub A {
	my $param = shift;
	update_progress 0, "Processing A($param)";
	update_progress 25;
	update_progress 50;
}

sub B($) {
	my $param = shift;
	update_progress 0, "Processing B($param)";
	update_progress 10;
	sub_progress {A($param)} 50;
	update_progress 60;
	update_progress 80;
}

sub_progress {A(1)} 25;
sub_progress {A(2)} 50;
sub_progress {B(3)} 100;
is_deeply(\@resultpercent,["0|Subprogress","0|Processing A(1)",6.25,12.5,25,"25|Processing A(2)",31.25,37.5,50,
	"50|Processing B(3)",55,"55|Processing A(3)",60,65,75,"80|Processing B(3)",90,100], "subprogress");

# nested loops & using next. Also check OO API and subclass
@resultpercent = ();
@SUBCLASS::ISA = qw(ProgressBar::Stack);
my $p = SUBCLASS->new(renderer => \&testrenderer, forceupdatevalue => 0);
$p->sub(sub {$p->for(sub {}, 1..10)}, 50);
my $i=0;
$p->sub(sub {
	$p->for(sub {
		$p->for(sub {
			no warnings;
			$i++;
			next if($i%2);
		}, 1..5);
	}, 1..10);
}, 100);
is_deeply(\@resultpercent,["0|",(map {$_*5} 1..10), (map {$_} 51..100), 100, 100], "nested loops & using next");
is($i,50,"nested loops & using next -- check number of iterations");

# map_progress
@resultpercent = ();
init_progress(renderer => \&testrenderer, forceupdatevalue => 0);
my @lengths = sub_progress { map_progress {
	update_progress(0,$_);
	length($_);
} qw(Banana Apple Pear Grapes) } 80;
is_deeply(\@resultpercent, ["0|","0|Banana",20,"20|Apple",40,"40|Pear",60,"60|Grapes",80], "map_progress");
is_deeply(\@lengths, [6,5,4,6], "map_progress -- result check");

# file_progress
open(F,">test.in") || die "Unable to create test file test.in: $!";
binmode F;
print F <<EOF;
twenty symbols row!
eighteen symbols!
sixteen symbols
and fourteen!
only twelve
10 chars!
8 chars
and 6
4!!
2
EOF
close F;
@resultpercent = ();
init_progress(renderer => \&testrenderer, forceupdatevalue => 0);
ok(open(F,"test.in"), "file_progress -- test file open");
is((stat(F))[7], 110, "file_progress -- check file length");
my @rowlengths;
sub_progress {
	<F>;
	file_progress {
	} \*F;
} 40;
sub_progress {
	seek F, 0, 0;
	file_progress {
		push @rowlengths, length($_);
	} \*F;
} 100;
close F;
is_deeply(\@rowlengths, [map {20-$_*2} 0..9], "file_progress -- check data");
is_deeply(\@resultpercent, ["0|", (map {(40-$_*2)/2*($_+1)/110*40} 0..9), (map {(40-$_*2)/2*($_+1)/110*60+40} 0..9),100], "file_progress -- progress");
unlink "test.in";

# threads
use Config;

SKIP: {
	skip "Threads not supported -- skipping threads tests",2 unless $Config{useithreads};
	require threads;

	@resultpercent = ();
	my ($thr) = threads->create(sub {
		init_progress(renderer => \&testrenderer, forceupdatevalue => 0);
		Time::HiRes::sleep 0.2;
		for_progress {Time::HiRes::sleep 0.4} 1..2;
		return @resultpercent;
	});
	init_progress(renderer => \&testrenderer, forceupdatevalue => 0);
	for_progress {Time::HiRes::sleep 0.4} 1..5;
	my @resultpercent2 = $thr->join();
	is_deeply(\@resultpercent, ["0|",20,40,60,80,100],"main thread");
	is_deeply(\@resultpercent2, ["0|",50,100],"second thread");
}

# count change
@resultpercent = ();
init_progress(renderer => \&testrenderer, forceupdatevalue => 0, count => 4);
for_progress {
	update_progress(1);
	update_progress(2);
	update_progress(3);
} 1,2;
is_deeply(\@resultpercent, ["0|",12.5,25,37.5,50,62.5,75,87.5,100],"count change");

# ETA
my @times = ();
sub testrenderer2($$) {
	my $value = shift;
	my $message = shift;
	my $progress = shift;
	if($message eq $lastmessage && scalar @resultpercent) {
		push @resultpercent, $value;
	} else {
		push @resultpercent, "$value|$message";
		$lastmessage = $message;
	}
	push @times, [$progress->running_time(), $progress->remaining_time(), $progress->total_time()];
}

@resultpercent = ();
init_progress(renderer => \&testrenderer2, forceupdatevalue => 0);
for_progress {Time::HiRes::sleep 0.2} 1..10;
is_deeply(\@resultpercent,["0|",10,20,30,40,50,60,70,80,90,100], "ETA -- result");
ok($times[0][0] < 0.01, "ETA -- running at start == 0");
ok($times[-1][1] < 0.01 , "ETA -- running at end == 0");
is_deeply([map {abs($_->[0]+$_->[1]-$_->[2]) < 0.001 ? 0 : "$_->[0] + $_->[1] != $_->[2]"} @times],
	[map {0} @times], "ETA -- running + remaining = total");
is_deeply([map {$times[$_][1] < $times[$_-1][1] ? 0 : "remaining($_) = $times[$_][1] < remaining(".($_-1).") = ".$times[$_-1][1]} 2..$#times],
	[map {0} 2..$#times], "ETA -- remaining time decreases");
is_deeply([map {abs($times[$_][2] - 2) < 0.3 ? 0 : "total($_) = $times[$_][2]"} 2..$#times],
	[map {0} 2..$#times], "ETA -- total time around 2 seconds");
