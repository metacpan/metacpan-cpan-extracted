#!/usr/bin/perl -w

die 'usage: ./shor.pl [number to factor]' unless @ARGV;

use strict;
use warnings;
use Quantum::Entanglement qw(:DEFAULT :complex :QFT);
$Quantum::Entanglement::destroy = 0;

my $num = $ARGV[0];

# do some early die'ing
die "$num is a multiple of two, here I am, brain the size..." unless $num %2;
die "$num is a non-integer, I only have whole numbers of fingers"
  unless $num == int($num);
die "$num is less than 15" unless $num >= 15;

print "Performing initial classical steps:\n";
# work out q value
my $q_power = int(2* log($num) / log(2)) +1;
my $q = 2 ** $q_power;

# pick some x so that x is coprime to n.
my $x;
do {
  $x = int(rand $num) + 1;
} until ($num % $x != 0 and $x > 2); #ok.. so this misses the point slightly

print "Using q:$q, x:$x\nStarting quantum steps\n";

# fill up a register with integers from 1..q
my $prob = 1/sqrt($q);
my $register1 = entangle(map {$prob, $_} (0..$q-1));

# apply transformation F = x**|a> mod n, store in register 2
# (need to do a p_func to avoid overflow while **)

sub power_mod {
  my ($state, $x1, $num1) = @_;
  my $rt = 1;
  return 1 if $state == 0;
  return 1 if $state == 1;
  for (1..$state) {
    $rt = ($rt * $x1) % $num1;
  }
  return $rt;
}
print "Performing F = x**|a> mod n\n";
my $register2 = p_func(\&power_mod, $register1, $x, $num);

# We now observe $register2, thus partially collapsing reg1
my $k = "$register2";

print "\$register2 collapsed to $k\n";
print "Finding period of F (this is where you wish for a QCD)\n";

# take a ft of the amplitudes of reg1, placing result in reg3
my $register3 = QFT($register1);

my $lqonr = "$register3"; # observe, this must be multiple of q/r
if ($lqonr == 0) {
  print "Got period of '0', halting\n"; exit(0);
}
my $period = int($q / $lqonr + 0.5); # rounding

print "Period of F = x**|a> mod n is $period\n";

# now given the period, we need to work out the factor of n
# work out the two thingies:

if ($period % 2 != 0) {
  print "$period is not an even number, doubling to";
  $period *=2;
  print " $period\n";
}

my $one = $x**($period/2) -1;
my $two = $x**($period/2) +1;

# one and two must have a gcd in common with n, which we now find...
print "$one * $two and $num might share a gcd (classical step)\n";
my ($max1, $max2) = (1,1);
for (2..$num) {
  last if $_ > $num;
  unless (($num % $_) || ($one % $_)) {
    $max1 = $_;
  }
  unless (($num % $_) || ($two % $_)) {
    $max2 = $_;
  }
}
print "$max1, $max2 could be factors of $num\n";


__END__;

=head1 NAME

  shor - A short demonstration of Quantum::Entanglement

=head1 SYNOPSIS

 ./shor.pl [number to factor (>14)]

=head1 DESCRIPTION

This program implements Shor's famous algorithm for factoring numbers.  A
brief overview of the algorithm is given below.

=head2 The important maths

Given a number B<n> which we are trying to factor, and some other number
which we have guessed, B<x>, we can say that:

 x**0 % n == 1 (as x**0 = 1, 1 % n =1)

There will also be some other number, B<r> such that

 x**r % n == 1

or, more specifically,

 x**(kr) % n ==1

in other words, the function

 F(a) = x**a % n

is periodic with period B<r>.

Now, starting from

 x**r = 1 % n

 x**(2*r/2) = 1 % n

 (x**(r/2))**2 - 1 = 0 % n

and, if r is an even number,

 (x**(r/2) - 1)*(x**(r/2) + 1) = 0 mod n

or in nice short words, the term on the left is an integer multiple of B<n>.
So long as x**(r/2) != +-1, at least one of the two brackets on the left
must share a factor with B<n>.

Shor's alorithm provides a way to find the periodicity of the function F
and thus a way to calculate two numbers which share a factor with n, it
is then easy to use a classical computer to find the GCD and thus a
factor of B<n>.

=head1 The steps of the algorithm

=head2 1. Remove early trivial cases

We have efficient classical methods for finding that 2 is a factor of 26,
so we do not need to use this method for this.

=head2 2. Pick an integer

Chose a number B<q> so that C<n**2 <= q <= 2n**2>, this is done on a
classical computer. (This is the size we will use for our quantum register.)

=head2 3. Select at random a number coprime to n

Think of some number less than B<n> so that B<n> and B<x> do not share
a common factor (if they do, we already know the answer...).

=head2 4. Fill a quantum register with integers from 0..q-1

This is where we create our first entangled variable, and is the first
non-classical step in this algorithm.

=head2 5. Calculate F, store in a second register

We now calculate C< F(a) = x**a % n> where a represents the superposition
of states in our first register, we store the result of this in our
second register.

=head2 6. Look at register2

We now look at the value of register two and get some value B<k>, this forces
register1 into
a state which can only collapse into values satisfying the equation

 x**a % n = k

The probability amplitudes for the remaining states are now all equal to zero,
note that we have not yet looked directly at register1.

=head2 7. Find period of register1

We now apply a fourier transform to the amplitudes of the states in
register1, storing the result as the probability amplitudes for a new
state with the values of register1.  This causes there to be a high
probability that the register will collapse to a value which is some
multiple of C<q/r>.

=head2 8. Observe register1

We now observe register1, and use the result to calculate a likely value
for B<r>.  From this we can easily calculate two numbers, one of which
will have a factor in common with n, by applying an efficient classical
algoirthm for finding the greatest common denominator, we will be able
to find a value which could be a factor of B<n>.

=head1 Things to remember

This algorithm does not claim to produce a factor of our number the first
time that it is run, there are various conditions which will cause it
to halt mid-way, for instance, the FT step can give a result of 0 which
is clearly useless.  The algorithm is better than any known classical one
because the expectation value of the time required to get a correct answer
is still O(n).

This also cannot factor a number which is prime (it being, as it were, prime)
and also cannot factor something which is a prime power (25, say).

=head1 COPYRIGHT

This code is copyright (c) Alex Gough (alex@rcon.org )2001.  This is
free software, you may use, modify and redistribute it under the same
terms as Perl itself.

=head1 BUGS

This is slow, being run on classical computers, ah well.

=cut

