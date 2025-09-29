#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity;

print "This shows action randomization with two options per step.\n";
print "Running multiple times should eventually show all possible branches.\n\n";
print "There are no cycles in this example.\n\n";

my %times=(tmmin=>1,tmavg=>10,tmmax=>99);

my %schedule=Schedule::Activity::buildSchedule(
	activities=>[[30,'root']],
	configuration=>{node=>{
		'root'=>{message=>'root',next=>[qw/A B/],finish=>'terminal',%times},
		'A'   =>{message=>'A',   next=>[qw/A-A A-B/],%times},
		'B'   =>{message=>'B',   next=>[qw/B-A B-B/],%times},
		'A-A' =>{message=>'A-A', next=>['terminal'],%times},
		'A-B' =>{message=>'A-B', next=>['terminal'],%times},
		'B-A' =>{message=>'B-A', next=>['terminal'],%times},
		'B-B' =>{message=>'B-B', next=>['terminal'],%times},
		terminal=>{
			message=>'terminal',
			tmmin=>0,tmavg=>0,tmmax=>0,
		},
	}},
);

my @materialized;
foreach my $entry (@{$schedule{activities}}) {
	my $tm=int(0.5+$$entry[0]);
	if($$entry[1]{message}) {
		push @materialized,[
			sprintf('%02d:%02d:%02d'
				,int($tm/3600)
				,int(($tm%3600)/60)
				,($tm%60))
			,$$entry[1]{message}
		];
	}
}
foreach my $entry (@materialized) { print join(' ',@$entry),"\n" }

