NAME
    PDL::Graphics::ColorDistance

VERSION
    0.0.1

DESCRIPTION
    This is a PDL implementation of the CIEDE2000 color difference formula.

SYNOPSIS
        use PDL::LiteF;
        use PDL::Graphics::ColorDistance;

        my $lab1 = pdl([ 50, 2.6772, -79.7751 ]);
        my $lab2 = pdl([ 50, 0,      -82.7485 ]);
        my $delta_e = delta_e_2000($lab1, $lab2);

        # $delta_e == 2.0425;

FUNCTIONS
  delta_e_2000
      Signature: (double lab1(c=3); double lab2(c=3); double [o]delta_e())

    Calculates the ΔE*00 (delta e, color distance) between two Lab colors

    Usage:

        my $delta_e = delta_e_2000($lab1, $lab2);

    If "delta_e_2000" encounters a bad value in any of the L, a, or b values
    the input values will be marked as bad

DEVELOPMENT
    This module is being developed via a git repository publicly available
    at http://github.com/ewaters/perl-PDL-Graphics-ColorDistance.

COPYRIGHT
    Copyright (c) 2013 Eric Waters and Shutterstock Images
    (http://shutterstock.com). All rights reserved. This program is free
    software; you can redistribute it and/or modify it under the same terms
    as Perl itself.

    The full text of the license can be found in the LICENSE file included
    with this module.

AUTHOR
    Eric Waters <ewaters@gmail.com>

