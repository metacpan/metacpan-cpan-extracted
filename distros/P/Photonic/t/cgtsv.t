=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Photonic::Utils qw(cgtsv);
use feature qw(say);
use constant N=>10;
use Test::More;

for my $D (3..N+2) { #first differences
    #solve (1 + i)(b_{n + 1} - b_n)=1 - i with homogeneous BCs
    my $c=r2C(zeroes($D));
    my $d=-ones($D)*(1 + i);
    my $e=ones($D)*(1 + i); $e->((-1)).=r2C(0);
    my $b=ones($D)*(1 - i); $b->((-1)).=(1-$D)*(1 - i);
    $b = cgtsv($c, $d, $e, $b);
    my $r=sequence($D)*(1 - i)/(1 + i);
    ok($b->approx($r)->all, "1st diff. cgtsv in D=$D")
      or diag "Got: ", $b, "\nExpected: ", $r;
}

for my $D (3..N+2) { #second differences
    #solve b_{n+1}-2{b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D)*(1 + i); $c->((-1)).=r2C(0);
    my $d=-2*ones($D)*(1 + i);
    my $e=ones($D)*(1 + i); $e->((-1)).=r2C(0);
    my $b=ones($D)*(1 - i);
    $b = cgtsv($c, $d, $e, $b);
    my $x=r2C(sequence($D));
    my $r=(-$D/2-($D-1)/2*$x+1/2*$x*$x)*(1 - i)/(1 + i);
    ok($b->approx($r)->all, "2nd diff. cgtsv in D=$D")
      or diag "Got: ", $b, "\nExpected: ", $r;
}

#solve (1 + i)(b_{n+1}-b_n)=1 - i with homogeneous BCs
my $c=r2C(zeroes(3));
my $d=-ones(3)*(1 + i);
my $e=ones(3)*(1 + i); $e->((-1)).=r2C(0);
my $b=ones(3)*(1 - i); $b->((-1)).=(1-3)*(1 - i);
my $y=cgtsv($c, $d, $e, $b);
my $r=sequence(3)*(1 - i)/(1 + i);
ok($y->approx($r)->all, "Omit output arguments");

#solve (1 + i)(b_{n+1}-b_n)=1 - i with homogeneous BCs
$c=r2C(zeroes(3));
$d=-ones(3)*(1 + i);
$e=ones(3)*(1 + i); $e->((-1)).=r2C(0);
$b=ones(3)*(1 - i); $b->((-1)).=(1-3)*(1 - i);
$y=cgtsv($c->inplace, $d, $e, $b);
ok($y->approx($r)->all, "Omit output arguments");

done_testing;
