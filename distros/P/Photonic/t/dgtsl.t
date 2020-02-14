# Test the function ExtraUtils function dgtsl

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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
use Photonic::ExtraUtils;
use feature qw(say);
use constant N=>10;
use Test::More tests => 2*N+2;

for my $D (3..N+2){ #first differencess
    #solve b_{n+1}-b_n=1 with homogeneous BCs
    my $c=zeroes($D);
    my $d=-ones($D);
    my $e=ones($D); $e->((-1)).=0;
    my $b=ones($D); $b->((-1)).=1-$D;
    my $info=pdl(short,0);
    dgtsl($c, $d, $e, $b, my $y=null, $info);
    my $r=sequence($D);
    ok($y->approx($r)->all, "1st diff. dgtsl in $D-D");
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D); $c->((0)).=0;
    my $d=-2*ones($D);
    my $e=ones($D); $e->((-1)).=0;
    my $b=ones($D);
    my $info=pdl(short,0);
    dgtsl($c, $d, $e, $b, my $y=null, $info);
    my $x=sequence($D);
    my $r=-$D/2-($D-1)/2*$x+1/2*$x*$x;
    ok($y->approx($r)->all, "2nd diff. dgtsl in $D-D");
}

#solve (1)(b_{n+1}-b_n)=1 with homogeneous BCs
my $c=zeroes(3);
my $d=-ones(3);
my $e=ones(3); $e->((-1)).=0;
my $b=ones(3); $b->((-1)).=(1-3);
my ($y, $info)=dgtsl($c, $d, $e, $b);
my $r=sequence(3);
ok($y->approx($r)->all, "Omit output arguments");
dgtsl($c, $d, $e, $b->inplace);
print "b $b\n r $r\n";
ok($b->approx($r)->all, "Inplace");


