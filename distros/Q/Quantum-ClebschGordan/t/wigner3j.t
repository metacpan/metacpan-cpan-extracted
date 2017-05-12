#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use Quantum::ClebschGordan;

while(my $line = <DATA>){
  chomp($line);
  $line =~ s/#.*//;
  next unless $line;
  last if $line =~ /__END__/;
  my @cols = split /\t/, $line;
  my $abbrv0 = pop @cols;
  next unless length($abbrv0);
  my ($j1,$j2,$m,$m1,$m2,$j) = @cols;
  my $cg = Quantum::ClebschGordan->new( j1=>$j1, j2=>$j2, m=>$m, m1=>$m1, m2=>$m2, j=>$j );
  my $c = $cg->wigner3j;
  is( $c, $abbrv0, "($j1,$j2,$m,$m1,$m2,$j) abbrvs match" );
}

__DATA__

#j1	j2	m	m1	m2	j	wigner3j
# where real coef is   sign(coef)*sqrt(abs(coef))

1/2	1/2	1	1/2	1/2	1	-1/3
1/2	1/2	0	1/2	-1/2	1	1/6
1/2	1/2	0	1/2	-1/2	0	1/2
1/2	1/2	0	-1/2	1/2	1	1/6
1/2	1/2	0	-1/2	1/2	0	-1/2

1	1/2	3/2	1	1/2	3/2	1/4
1	1/2	1/2	1	-1/2	3/2	-1/12
1	1/2	1/2	1	-1/2	1/2	-1/3
1	1/2	1/2	0	1/2	3/2	-1/6
1	1/2	1/2	0	1/2	1/2	1/6

