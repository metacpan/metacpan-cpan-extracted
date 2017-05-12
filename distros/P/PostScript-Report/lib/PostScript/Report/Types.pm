#---------------------------------------------------------------------
package PostScript::Report::Types;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: type library for PostScript::Report
#---------------------------------------------------------------------

our $VERSION = '0.13';

use Carp 'confess';

use MooseX::Types -declare => [qw(
  BorderStyle BorderStyleNC BWColor Color Component Container
  FontObj FontMetrics FooterPos HAlign
  Parent Report RGBColor RGBColorHex RptValue SectionType VAlign
)];
use MooseX::Types::Moose qw(ArrayRef Num Str);

enum(BorderStyle, [qw(0 1 T B L R TB LR TL TR BL BR TLR BLR TBL TBR)]);

subtype BorderStyleNC,
  as Str,
  where { /^(?: [01] | [TBLR]* )$/xi };

coerce BorderStyle,
  from BorderStyleNC,
  via {
    return 0 unless $_;
    return 1 if /1/;

    my $style = '';
    foreach my $side (qw(T B L R)) {
      $style .= $side if /$side/i;
    }

    return 1 if $style eq 'TBLR';
    $style;
  }; # end coerce BorderStyle from BorderStyleNC

role_type  Component,   { role  => 'PostScript::Report::Role::Component' };
role_type  Container,   { role  => 'PostScript::Report::Role::Container' };
class_type FontObj,     { class => 'PostScript::Report::Font' };
class_type FontMetrics, { class => 'PostScript::File::Metrics' };
class_type Report,      { class => 'PostScript::Report' };

enum(FooterPos, [qw(bottom split top)]);

enum(HAlign, [qw(center left right)]);

subtype RptValue,
  as Str|role_type('PostScript::Report::Role::Value');

subtype Parent,
  as Container|Report;

enum(SectionType, [qw(page report)]);

enum(VAlign, [qw(bottom top)]);

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

1;

__END__

=head1 NAME

PostScript::Report::Types - type library for PostScript::Report

=head1 VERSION

This document describes version 0.13 of
PostScript::Report::Types, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

These are the custom types used by L<PostScript::Report>.

=head1 TYPES

=head2 BorderStyle

A valid border style (C<0>, C<1>, or any combination of C<T>, C<B>,
C<L>, and C<R>).  Will be forced into canonical form.

=head2 Color

This is a number in the range 0 to 1 (where 0 is black and 1 is
white), or an arrayref of three numbers C<[ Red, Green, Blue ]> where
each number is in the range 0 to 1.

In addition, you can specify an RGB color in the HTML hex triplet form
prefixed by C<#> (like C<#FFFF00> or C<#FF0> for yellow).

=head2 Component

An object that does L<PostScript::Report::Role::Component>.

=head2 Container

An object that does L<PostScript::Report::Role::Container>.

=head2 FontObj

A L<PostScript::Report::Font>.

=head2 FontMetrics

A L<PostScript::File::Metrics>.

=head2 HAlign

C<center>, C<left>, or C<right>

=head2 Report

A L<PostScript::Report>.

=head2 RptValue

Something you can pass to L<PostScript::Report/get_value>.
A string or an object that does L<PostScript::Report::Role::Value>.

=head2 Parent

An object that is a suitable C<parent> for a Component.

=head2 VAlign

C<bottom> or C<top>

=head1 SEE ALSO

L<MooseX::Types>, L<MooseX::Types::Moose>.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-Report AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-Report >>.

You can follow or contribute to PostScript-Report's development at
L<< https://github.com/madsen/postscript-report >>.

=head1 ACKNOWLEDGMENTS

I'd like to thank Micro Technology Services, Inc.
L<http://www.mitsi.com>, who sponsored development of
PostScript-Report, and fREW Schmidt, who recommended me for the job.
It wouldn't have happened without them.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Christopher J. Madsen.

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
