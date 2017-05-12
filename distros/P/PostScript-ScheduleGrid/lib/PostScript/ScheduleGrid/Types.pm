#---------------------------------------------------------------------
package PostScript::ScheduleGrid::Types;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 Dec 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: type library for PostScript::ScheduleGrid
#---------------------------------------------------------------------

our $VERSION = '0.05'; # VERSION
# This file is part of PostScript-ScheduleGrid 0.05 (August 22, 2015)

use MooseX::Types -declare => [qw(
  BWColor Color Dimension FontMetrics RGBColor RGBColorHex Style
  TimeHeaders
)];
use MooseX::Types::Moose qw(ArrayRef Num Str);

use POSIX qw(floor modf);

class_type FontMetrics, { class => 'PostScript::File::Metrics' };

role_type Style, { role => 'PostScript::ScheduleGrid::Role::Style' };

#---------------------------------------------------------------------
subtype Dimension,
  as Num,
  where { (modf($_ * 32))[0] == 0 };

coerce Dimension,
  from Num,
  via { floor($_ * 32 + 0.5) * (1/32); };

#---------------------------------------------------------------------
subtype BWColor,
  as Num,
  where { $_ >= 0 and $_ <= 1 };

subtype RGBColor,
  as ArrayRef[BWColor],
  where { @$_ == 3 };

subtype RGBColorHex,
  as Str,
  # Must have a multiple of 3 hex digits after initial '#':
  where { /^#((?:[0-9a-f]{3})+)$/i };

coerce RGBColor,
  from RGBColorHex,
  via {
    my $color = substr($_, 1);

    my $digits = int(length($color) / 3); # Number of digits per color
    my $max    = hex('F' x $digits);      # Max intensity per color

    [ map {
        my $n = sprintf('%.3f',
                        hex(substr($color, $_ * $digits, $digits)) / $max);
        $n =~ s/\.?0+$//;
        $n
      } 0 .. 2 ];
  };

subtype Color,
  as BWColor|RGBColor;

#---------------------------------------------------------------------
subtype TimeHeaders,
  as ArrayRef[Str],
  where { @$_ == 2 };

1;

__END__

=head1 NAME

PostScript::ScheduleGrid::Types - type library for PostScript::ScheduleGrid

=head1 VERSION

This document describes version 0.05 of
PostScript::ScheduleGrid::Types, released August 22, 2015
as part of PostScript-ScheduleGrid version 0.05.

=head1 DESCRIPTION

These are the custom types used by L<PostScript::ScheduleGrid>.

=head1 TYPES

=head2 Color

This is a number in the range 0 to 1 (where 0 is black and 1 is
white), or an arrayref of three numbers C<[ Red, Green, Blue ]> where
each number is in the range 0 to 1.

In addition, you can specify an RGB color as a string in the HTML hex
triplet form prefixed by C<#> (like C<#FFFF00> or C<#FF0> for yellow).

=head2 Dimension

A floating-point number rounded to the nearest 1/32.  Helps avoid
round-off errors in PostScript calculations.

=head2 FontMetrics

A L<PostScript::File::Metrics>.

=head2 Style

A class that does L<PostScript::ScheduleGrid::Role::Style>.

=head1 SEE ALSO

L<MooseX::Types>, L<MooseX::Types::Moose>.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-ScheduleGrid AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-ScheduleGrid >>.

You can follow or contribute to PostScript-ScheduleGrid's development at
L<< https://github.com/madsen/postscript-schedulegrid >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
