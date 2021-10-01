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
use Photonic::CharacteristicFunctions qw(triangle isosceles ellipse);
use Test::More;
TRIANGLE: {
     my ($N, $r0, $deltar, $theta0)=(11, 0.5, 0.2, 0.1);
     my $b=triangle($N, $r0, $deltar, $theta0);
     ok(defined $b, "Triangle");
}
 ELLIPSE: {
     my ($N, $ff, $ecc) = (11, 0.25, 0.5);
     my $e=ellipse($N, $ff, $ecc);
     ok(defined $e, "Triangle");
}
 ISOSCELES: {
     my ($N, $r0, $delta2,$delta3, $theta0)=(11, 0.5, 0.1, 0.2, 0.1);
     my $i=isosceles($N, $r0, $delta2, $delta3, $theta0);
     ok(defined $i, "Isosceles");
}

done_testing;
