#!/usr/bin/perl

# This provides some sample results when adding weights to goals, and comments on the behaviors.
#
# Goals with attribute weights can be useful for more complicated scheduling configurations,
# but for simple schedules, such as those with basic alternation, node filtering may be a
# more straightforward choice.
#
# In most cases, adjusting goal weights leads to repetition of a "winning action".  With
# more complicated configurations it's possible to get a "weighted combination" of actions.
# While exact values can be determined with linear algebra and matrix theory, general goal
# searching is still based on random schedule construction.

use strict;
use warnings;
use Schedule::Activity;
my ($scheduler,%schedule);
my %fixedtime=(tmmin=>1,tmavg=>1,tmmax=>1);

#
# For basic alternation, weights simply change the winning action when maximizing values.
#
print "\nBasic alternation\n";
$scheduler=Schedule::Activity->new(configuration=>{node=>{
	start=>{next=>[qw/B C/],finish=>'finish',tmavg=>0,attributes=>{bee=>{set=>0},cee=>{set=>0}}},
	finish=>{tmavg=>0},
	B=>{attributes=>{bee=>{incr=>+1},cee=>{incr=>+0}},%fixedtime,next=>[qw/B C finish/]},
	C=>{attributes=>{bee=>{incr=>+0},cee=>{incr=>+2}},%fixedtime,next=>[qw/B C finish/]},
}});

# With no weighting, the winning schedule only uses actions that yield the largest attribute.
# In this case, C always wins because cee increments more than bee.
%schedule=$scheduler->schedule(activities=>[[5,'start',{goal=>{cycles=>436,attribute=>{
	bee=>{op=>"max"},
	cee=>{op=>"max"}
}}}]]);
print $schedule{attributes}{cee}{y}," (expect 10) shows C/cee was chosen all five times.\n";

# When the weighting of bee is sufficient, the schedule fully flips to B/bee.
%schedule=$scheduler->schedule(activities=>[[5,'start',{goal=>{cycles=>436,attribute=>{
	bee=>{op=>"max",weight=>11},
	cee=>{op=>"max"}
}}}]]);
print $schedule{attributes}{bee}{y}," (expect 5) shows B/bee was chosen all five times.\n";

#
# Combinations of attributes also yield a single winning action for basic alternation.
#
print "\nAlternation with attribute combinations\n";
my @A=([rand(),rand()],[rand(),rand()]);
$scheduler=Schedule::Activity->new(configuration=>{node=>{
	start=>{next=>[qw/B C/],finish=>'finish',tmavg=>0,attributes=>{bee=>{set=>0},cee=>{set=>0}}},
	finish=>{tmavg=>0},
	B=>{message=>'B',attributes=>{bee=>{incr=>$A[0][0]},cee=>{incr=>$A[0][1]}},%fixedtime,next=>[qw/B C finish/]},
	C=>{message=>'C',attributes=>{bee=>{incr=>$A[1][0]},cee=>{incr=>$A[1][1]}},%fixedtime,next=>[qw/B C finish/]},
}});

# Suppose bee has a weight of W, and cee has a fixed weight of 1.  Then the scores for B and C:
#   W*A[0][0]+A[0][1] for each B
#   W*A[1][0]+A[1][1] for each C
# Whichever is greater will be the scheduling winner.  That is B>C when
#   W*(A[0][0]-A[1][0])>(A[1][1]-A[0][1])

my $Wcritical=($A[1][1]-$A[0][1])/($A[0][0]-$A[1][0]); # divide by zero if you're really lucky!
my $Wdirection=($A[0][0]-$A[1][0]>0?1:-1);             # inequality may flip
my %sums;

# With slightly larger and smaller weights, the results are
%schedule=$scheduler->schedule(activities=>[[5,'start',{goal=>{cycles=>436,attribute=>{
	bee=>{op=>"max",weight=>$Wcritical+$Wdirection},
	cee=>{op=>"max"}
}}}]]);
%sums=(); foreach my $msg (@{$schedule{activities}}) { $sums{$$msg[2]{msg}[0]}++ }
print "B was chosen $sums{B} times.\n";
#
%schedule=$scheduler->schedule(activities=>[[5,'start',{goal=>{cycles=>436,attribute=>{
	bee=>{op=>"max",weight=>$Wcritical-$Wdirection},
	cee=>{op=>"max"}
}}}]]);
%sums=(); foreach my $msg (@{$schedule{activities}}) { $sums{$$msg[2]{msg}[0]}++ }
print "C was chosen $sums{C} times.\n";

#
# When cycles are more complicated than alternation, a combination of actions is possible.
#
print "\nCyclic schedules\n";
$scheduler=Schedule::Activity->new(configuration=>{node=>{
	start=>{next=>[qw/B C/],finish=>'finish',tmavg=>0,attributes=>{bee=>{set=>0},cee=>{set=>0}}},
	finish=>{tmavg=>0},
	B=>{message=>'B',attributes=>{bee=>{incr=>+1},cee=>{incr=>+0}},%fixedtime,next=>[qw/C finish/]},
	C=>{message=>'C',attributes=>{bee=>{incr=>-.5},cee=>{incr=>+1.5}},%fixedtime,next=>[qw/B C finish/]},
}});
print "(Note that the weight does affect the balance of actions for this configuration)\n";
foreach my $weight (0.5,1,2) {
	%schedule=$scheduler->schedule(activities=>[[5,'start',{goal=>{cycles=>436,attribute=>{
		bee=>{op=>"max",weight=>$weight},
		cee=>{op=>"max",weight=>1}
	}}}]]);
	print 'Actions ',join('',map {$$_[2]{msg}[0]} @{$schedule{activities}})," for weight $weight\n";
}
# Note because of the schedule length, the only schedules possible are:
# BCBCC BCCBC BCCCC CBCBC CBCCC CCBCC CCCBC CCCCC

# For maximum/minimum goals, therefore, the outcomes from weights are often a property of the
# scheduling configuration itself, and simply doubling the weight for one attribute doesn't
# necessarily double the appearances of related actions.
#
# Also note that, at this time, goal seeking is single-level based on the weighted, computed
# score.  Two-level goal seeking, where ties are broken by the second-weight item, are not
# implemented.  The scheduling result will be the best overall randomly generated schedule.

