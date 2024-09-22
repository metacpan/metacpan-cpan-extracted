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

#Check that the values and states retrieved from a file by AllH coincide
#with those kept in memory.

use strict;
use warnings;
use PDL;
use Test::More;
use lib 't/lib';
use TestUtils;

my @coeffs = qw(as bs b2s cs bcs gs);
my @all_vars = (qw(iteration), @coeffs);

my $fn = make_fn(); #output file name

my ($all_stash, $states_stash) = {};
{
    #Check haydock coefficients for simple 1D system
    my ($a) = make_store(
        zeroes(11)->xvals<5, #1D system
	[1], 10,
	{ keepStates=>1, storeAllFN=>$fn },
    );
    $all_stash->{$_} = $a->$_ for @all_vars;
    $states_stash = $a->states->copy;
}

{
    #full restore allh from previous calculation
    my ($a) = make_store(zeroes(11)->xvals<5, [1], 10, {loadAllFN=>$fn});
    is($all_stash->{iteration}, $a->iteration,
       "Number of iterations 1D longitudinal");
    ok(agree(pdl($all_stash->{$_}), pdl($a->$_)), "1D L restored $_") for @coeffs;
    my $readstates = $a->states;
    ok(Cagree($readstates, $states_stash), "1D L restored states");
}

{
    #partial restore allh from previous calculation
    my ($a, $g) = make_store(zeroes(11)->xvals<5, [1], 1, {keepStates=>1, storeAllFN=>$fn});
    is($a->iteration, 1, "Can stop before exhausting coefficients 1D L");
    my $a2=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>10,
					keepStates=>1, loadAllFN=>$fn);
    my $a3=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>10, keepStates=>1);
    $a2->run;
    $a3->run;
    is $a2->iteration, $a3->iteration, 'same number of iterations';
    ok(agree(pdl($a2->$_), pdl($a3->$_)), "1D L restarted $_") for @all_vars;
    ok(Cagree($a2->states, $a3->states), "1D L restarted states");
}

done_testing;
