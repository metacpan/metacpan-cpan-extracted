
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::ColorDistance;

@EXPORT_OK  = qw(  delta_e_2000 PDL::PP delta_e_2000 );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::Graphics::ColorDistance::VERSION = '0.0.1';
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::ColorDistance $VERSION;





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







=head1 FUNCTIONS



=cut






=head2 delta_e_2000

=for sig

  Signature: (double lab1(c=3); double lab2(c=3); double [o]delta_e())


=for ref

Calculates the ΔE*00 (delta e, color distance) between two Lab colors

=for usage

Usage:

    my $delta_e = delta_e_2000($lab1, $lab2);



=for bad


If C<delta_e_2000> encounters a bad value in any of the L, a, or b values the input values will be marked as bad



=cut






*delta_e_2000 = \&PDL::delta_e_2000;




=head1 DEVELOPMENT

This module is being developed via a git repository publicly available at http://github.com/ewaters/perl-PDL-Graphics-ColorDistance.

=head1 COPYRIGHT

Copyright (c) 2013 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut



;



# Exit with OK status

1;

		   