#!/usr/bin/perl

pp_add_exported('', 'delta_e_2000');

$PDL::Graphics::ColorDistance::VERSION = '0.0.1';

pp_setversion("'$PDL::Graphics::ColorDistance::VERSION'");

pp_addpm({At=>'Top'}, <<'EOD');

=encoding utf-8

=head1 NAME

PDL::Graphics::ColorDistance

=head1 VERSION

0.0.1

=head1 DESCRIPTION

This is a PDL implementation of the CIEDE2000 color difference formula.

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::Graphics::ColorDistance;

    my $lab1 = pdl([ 50, 2.6772, -79.7751 ]);
    my $lab2 = pdl([ 50, 0,      -82.7485 ]);
    my $delta_e = delta_e_2000($lab1, $lab2);

    # $delta_e == 2.0425;

=cut

use strict;
use warnings;

use Carp;
use PDL::LiteF;

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

EOD

pp_addhdr('
#include <math.h>
#include "color_distance.h"  /* Local decs */
'
);

pp_def('delta_e_2000',
    Pars => 'double lab1(c=3); double lab2(c=3); double [o]delta_e()',
    Code => '
        deltaE2000( $P(lab1), $P(lab2), $P(delta_e) );
    ',

    HandleBad => 1,
    BadCode => '
        /* First check for bad values */
        if ($ISBAD(lab1(c=>0)) || $ISBAD(lab1(c=>1)) || $ISBAD(lab1(c=>2)) ||
            $ISBAD(lab2(c=>0)) || $ISBAD(lab2(c=>1)) || $ISBAD(lab2(c=>2))) {
            loop (c) %{
                $SETBAD(lab1());
                $SETBAD(lab2());
            %}
            /* skip to the next triple */
        }
        else {
            deltaE2000( $P(lab1), $P(lab2), $P(delta_e) );
        }
    ',

    Doc => <<'DOCUMENTATION',

=for ref

Calculates the ΔE*00 (delta e, color distance) between two Lab colors

=for usage

Usage:

    my $delta_e = delta_e_2000($lab1, $lab2);

DOCUMENTATION
    BadDoc => <<BADDOC,

If C<delta_e_2000> encounters a bad value in any of the L, a, or b values the input values will be marked as bad

BADDOC
);


pp_addpm(<<'EOD');

=head1 DEVELOPMENT

This module is being developed via a git repository publicly available at http://github.com/ewaters/perl-PDL-Graphics-ColorDistance.

=head1 COPYRIGHT

Copyright (c) 2013 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

EOD

pp_done();
