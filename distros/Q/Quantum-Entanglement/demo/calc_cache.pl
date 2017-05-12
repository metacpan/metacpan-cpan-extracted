#!/usr/bin/perl -w

use Quantum::Entanglement qw(:DEFAULT);

# list of possible input values for our computationally slow function:

my @inputsA = (1,1,1,2,1,3,1,4,1,5,1,6,1,7,1,8,1,9,1,10);
my @inputsB = (1,1,1,2,1,3,1,4,1,5,1,6,1,7,1,8,1,9,1,10);

# make a superposition of these (we don't need to worry about probs here...)

my $inputsA = entangle( @inputsA );
my $inputsB = entangle( @inputsB );

# calculate our nasty function, save the entangled answer
# this should have many steps and be nasty, but that'll take too long

my $answer = $inputsA * $inputsB;

# store the global state space

my $state = save_state($inputsA, $inputsB, $answer);

# set up "conform" mode
$Quantum::Entanglement::conform = 1;

print "Enter two numbers between 1 and 10 to multiply\n";
while (<>) {
  last unless /(\d+)[^\d]*(\d+)/;
  1 if $inputsA == $1; # yes, really ==, just in void context
  1 if $inputsB == $2;
  print "\n$1 * $2 = $answer\n";
  ($inputsA, $inputsB, $answer) = $state->restore_state; # again!
}
