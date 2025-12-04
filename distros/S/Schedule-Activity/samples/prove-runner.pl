#!/usr/bin/perl

# Sample output
# ...
# ...
# [11:58:13] t/schedule/activity.t .. ok       69 ms ( 0.00 usr  0.00 sys +  0.05 cusr  0.02 csys =  0.07 CPU)
# [11:58:13]
# All tests successful.
# Files=1, Tests=18,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.05 cusr  0.02 csys =  0.09 CPU)
# Result: PASS
# [11:58:13] t/schedule/activity/annotation.t .. ok       55 ms ( 0.00 usr  0.00 sys +  0.06 cusr  0.00 csys =  0.06 CPU)
# [11:58:13]
# All tests successful.
# Files=1, Tests=3,  0 wallclock secs ( 0.01 usr  0.01 sys +  0.06 cusr  0.00 csys =  0.08 CPU)
# Result: PASS
#
# 7 t/schedule/activity.t::Node+Message attributes
# 5 t/schedule/activity/node.t::slack/buffer
# 4 t/schedule/activity/message.t::Primary messages
# 3 t/schedule/activity.t::Annotations
# 3 t/schedule/activity.t::Named messages
# 3 t/schedule/activity.t::Node filtering
# 3 t/schedule/activity.t::edge cases
# 3 t/schedule/activity/attribute.t::Change:  Boolean
# 3 t/schedule/activity/attribute.t::Change:  Integers
# 3 t/schedule/activity/node.t::defaulting
# 3 t/schedule/activity/nodefilter.t::Values
# 2 t/schedule/activity.t::Attribute recomputation
# 2 t/schedule/activity.t::Message attributes
# 2 t/schedule/activity.t::Simple scheduling
# ...

use strict;
use warnings;
use Data::Dumper;
use Schedule::Activity;

sub getTests {
	my (@res,@files);
	my @tocheck=('t');
	while(@tocheck) {
		my $path=shift(@tocheck);
		foreach my $fn (glob("$path/*")) {
			if(-d $fn) { push @tocheck,$fn }
			else { push @files,$fn }
		}
	}
	foreach my $file (@files) {
		open(my $fh,'<',$file) or next;
		local($/);
		my $code=<$fh>;
		close($fh);
		while($code=~m/^\s*subtest\s+(.*?)\s*=>/mg) {
			my $name=$1;
			if   ($name=~/^".*"$/) { $name=~s/^"|"$//g }
			elsif($name=~/^'.*'$/) { $name=~s/^'|'$//g }
			push @res,[$file,$name];
		}
	}
	return @res;
}

sub singleTestCmd {
	my ($fn,$subtest)=@_;
	return qq|SUBTESTRE='\Q$subtest\E' prove --timer --exec='perl -I. -MSubtestSelect' ../$fn|;
}

sub getRuntimes {
	my (@tests)=@_;
	my %runtimes;
	foreach my $test (@tests) {
		my $cmd=singleTestCmd(@$test);
		print STDERR "$$test[0] $$test[1] ";
		my $res=qx/$cmd 2>&1/;
		if($res=~/\Q$$test[0]\E.* ok *(\d+) +ms/) { $runtimes{join('::',@$test)}=$1; print STDERR "$1ms" }
		print STDERR "\n";
	}
	return %runtimes;
}

if(($ARGV[0]//'') ne '--runit') {
	print STDERR "Please call as '$0 --runit'\n";
	exit(0);
}
if(!-e 'prove-runner.dat') {
	my @tests=getTests();
	my %runtimes=getRuntimes(@tests);
	my %configuration=(node=>{
		'test cycling'=>{finish=>'done testing',tmavg=>0,next=>[keys %runtimes]},
		'done testing'=>{message=>'Testing concluded',tmavg=>0},
		map {($_=>{
			message=>$_,
			tmavg=>$runtimes{$_},
			next=>['done testing','test cycling'],
		})} keys(%runtimes)
	});
	open(my $fh,'>','prove-runner.dat');
	print $fh Dumper(\%configuration);
	close($fh);
	print STDERR "Saved into ./prove-runner.dat\n";
}
else {
	my $runtimeratio=0.45;
	my %configuration;
	open(my $fh,'<','prove-runner.dat');
	{local($/);my $t=<$fh>;my $VAR1;eval "$t";%configuration=%$VAR1};
	close($fh);
	my %counts=map {$_=>0} keys(%{$configuration{node}}); delete(@counts{'test cycling','done testing'});
	my $scheduler=Schedule::Activity->new(configuration=>{%configuration});
	my %schedule=$scheduler->schedule(activities=>[[10_000*$runtimeratio,'test cycling']]);
	foreach my $test (grep {/::/} map {$$_[2]{msg}[0]} @{$schedule{activities}}) {
		my ($file,$subtest)=split(/::/,$test,2);
		my $cmd=singleTestCmd($file,$subtest);
		my $status=system($cmd);
		if($status!=0) { exit(1) }
		$counts{"${file}::$subtest"}++;
	}
	foreach my $k (sort {($counts{$b}<=>$counts{$a})||($a cmp $b)} keys %counts) { print "$counts{$k} $k\n" }
	exit(0);
}
