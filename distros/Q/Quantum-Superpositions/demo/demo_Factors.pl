#! /usr/local/bin/perl -w

use Quantum::Superpositions UNARY => ['CORE::int'];

sub factors 
{
	eigenstates (int($_[0] / any(2..$_[0]-1)) == ($_[0] / any(2..$_[0]-1)));
}

while (<>)
{
	print int($_), "\n";
	print "factors: ", join(",", factors($_)), "\n";
}
