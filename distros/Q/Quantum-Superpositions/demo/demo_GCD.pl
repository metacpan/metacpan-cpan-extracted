#! /usr/local/bin/perl

use Quantum::Superpositions ( UNARY => ['CORE::int'] );

sub factors 
{
	eigenstates (int($_[0] / any(2..$_[0]-1)) == ($_[0] / any(2..$_[0]-1)));
}

sub GCD
{
	my ($x, $y) = @_;
	my $common = all(any(factors($x)), any(factors($y)));
	any(eigenstates $common) >= all(eigenstates $common);
}

while (<>)
{
	chomp;
	my ($x,$y) = split;
	print "factors($x): ", join(",",factors($x)), "\n";
	print "factors($y): ", join(",",factors($y)), "\n";
	print "GCD($x,$y):  ", GCD($x,$y), "\n";
}
