#!/usr/bin/perl -w

# First four command-line args are taken as:
#   1 #samples to simulate
#       these are a mild exponentially-growing set of 'request' values
#   2 #iterations to test
#       high iterations shows more honest approximations
#   3 Random::Skew::GRAIN
#       what size bucket-lists to use before recursing
#   4 Growth factor for samples
#       for building our initial 'request' values
use strict;

use Random::Skew;

my $samples    = shift // 26;
my $iterations = shift // 100_000;
my $grain      = shift // 47;
my $grow       = shift // 1.2;

# Configure:
Random::Skew::GRAIN( $grain ); # frob at your leisure

# Build an exponential 'request' set, to demonstrate fidelity to
# high-end and low-end population probabilities
my $x = 7;
my $c = 'a';
my %spec;
$spec{ $c++ } = int( $x *= $grow ) while $samples-- > 0;

my $tot = 0;
$tot += $spec{ $_ } for keys %spec;


# Set up Random::Skew objects:
my $rand = Random::Skew->new( %spec );
# Explore $rand using different values for GRAIN when single-stepping

#$DB::single = 1;



# Here we go:
my %output;

for ( my $ct = $iterations ; $ct > 0 ; $ct -- ) {

    my $output = $rand->item;
    $output{ $output }++;

}

sub sequence {
    $spec{$b} <=> $spec{$a}
    or
    $a cmp $b
}

# Now show what we've got. The higher $iterations, the closer the
# results are to the originally-requested proportions (with a bit
# of fudging, due to rounding).
print "\nX        Count (  %  )        Req (  %  )   Ratio\n";
foreach my $item ( sort sequence keys %spec ) {

    my $n = $output{ $item } // 0;

    my $pct  = 100 * $n           / $iterations;
    my $goal = 100 * $spec{$item} / $tot;
    my $ratio = $pct / $goal - 1.0;

    my $extra = '';
       $extra = ' <-- high' if $ratio > +.05;
       $extra = ' <-- HIGH' if $ratio > +.10;
       $extra = ' <-- low'  if $ratio < -.05;
       $extra = ' <-- LOW'  if $ratio < -.10;

    printf "%-3s  %9d (%5.2f)  %9d (%5.2f)  %5.2f%s\n",
        $item,
        $output{$item} // 0,
        $pct,
        $spec{$item},
        $goal,
        $ratio,
        $extra
    ;

}

print <<INFO;
COUNT shows how many were generated for that 'bucket'.
REQ   shows how many were requested
  (the percentages are what we are comparing)
RATIO shows how close the randomizer got to the requested percentages.
  "<-- HIGH" means off by 10%+
  "<-- high" means off by 5-10%
  "<-- low" means off by 5-10%
  "<-- LOW" means off by 10%+
Adjust Random::Skew::GRAIN to tweak fidelity as needed. (Sometimes prime
numbers work well, often larger values help...)

Also see Random::Skew::Test.
INFO
