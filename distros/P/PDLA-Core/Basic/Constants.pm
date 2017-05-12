=head1 NAME

PDLA::Constants -- basic compile time constants for PDLA

=head1 DESCRIPTION

This module is used to define compile time constant
values for PDLA.  It uses the constant module for
simplicity and availability.  We'll need to sort
out exactly which constants make sense but PI and
E seem to be fundamental.

=head1 SYNOPSIS

 use PDLA::Constants qw(PI E);
 print 'PI is ' . PI . "\n";
 print 'E  is ' .  E . "\n";

=cut

package PDLA::Constants;
our $VERSION = "0.02";
$VERSION = eval $VERSION;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(PI E I J);  # symbols to export

use PDLA::Lite;
use PDLA::Complex qw(i);
                           
=head2 PI

The ratio of a circle's circumference to its diameter

=cut

use constant PI    => 4 * atan2(1, 1);

=head2 DEGRAD

The The number of degrees of arc per radian (180/PI)

=cut

use constant DEGRAD => 180/PI;

=head2 E

The base of the natural logarithms or Euler's number

=cut

use constant E     => exp(1);

=head2 I

The imaginary unit, C< I*I == -1 >

=cut

use constant I     => i;

=head2 J

The imaginary unit for engineers, C< J*J == -1 >

=cut

use constant J     => i;

=head1 COPYRIGHT & LICENSE

Copyright 2010 Chris Marshall (chm at cpan dot org).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
