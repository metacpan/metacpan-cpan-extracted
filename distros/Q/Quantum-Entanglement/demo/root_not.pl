#!/usr/bin/perl -w
use strict;
use warnings;

use Quantum::Entanglement qw(:DEFAULT :complex);

my $foo = entangle(1, 0);           #     foo = |0>

$foo = q_logic(\&root_not, $foo);   # now foo = |0> + i|1>

$foo = q_logic(\&root_not, $foo);   # but foo = |1> ie (root-not)**2 foo

print "\$foo is true!\n" if $foo;

sub root_not {
  my ($prob, $val) = @_;
  return( $prob * (i* (1/sqrt(2))), $val,      # same state => *i/root(2)
	  $prob * (1/sqrt(2)), !$val ? 1 : 0); # diff state => *1/root(2)
}

__END__;

=head1 root_not - Demonstration of a root-not logic gate.

=head1 SYNOPSIS

 ./root_not.pl

prints

 $foo is true!

=head1 DESCRIPTION

This is an implementation of a root_not gate using Quantum::Entanglement.

=head2 Logic Gates

The simplist possible logic gate is one which maps a single input {0,1} to
a single output {0,1}.  This can be illustrated using the following diagram:

 Possible Inputs Gate    Possible Outputs
                  a
  0  -----------|----|-------  0
                |\b /|
                | \/ |
                | /\ |
                |/c \|
  1  -----------|----|-------  1
                  d

The constants a,b,c,d represent the probability with which a certain input
will map onto a given output. For instance, a=d=1, b=c=0 is a pass through
gate and a=d=0, b=c=1 is a convential NOT gate.

We can also use this gate as a random number generator, if we set a=b=c=d=0.5
then the output of this machine will be 0 half of the time and 1 the other
half of the time, the output will also be uncorrelated with the input.
It is also easy to see that if we were to chain two of these gates together
we would still get a random stream as our output.

All the above is entirely classical.  Things get a little wierd if instead
of using straight probabilities for a,b,c,d we instead use probability
amplitudes which we allow to be complex numbers.  We need them to be
normalised so that (a**2 + b**2) == 1 and (c**2+d**2)==1 rather than
(a+b)==1 as before.

Now, if we let a=d=i/root(2) and b=c=1/root(2).  With one gate, we transform
an input state of |0> into an output state of i|0> + 1|1> and an input
state of 1 into an output state of 1|1> + i|0> (without normalisation).
If we look at the results of this single gate, we will measure 0
with a probability of |(i)|/2 == 0.5 and 1 with a probability of
(1)/2 == 0.5 (for an input of 0).
In this case, we have the same output as we did with
the classical random number generator.

If we do not look at the results of this gate and feed it into a second
gate we see the following with an input of 0 (normalization delayed until end):

 state at start        = |0>

 state after one gate  = i|0>            + 1|1>

 state after two gates = i*i|0> + 1*i|1> + 1*i|1> + 1*1|0>

                       = (-1+1)|0> + (i+i)|1>

Which if observed collapses to |1>.  If an input of 1 is used on the first
gate, then it is easy to show that an output of 0 will come from the
second gate.  Here we have a device where if only one is used, behaves
as a random number generator, but if two are used in series, acts as a NOT
gate.

=cut

