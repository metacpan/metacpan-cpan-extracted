#---------------------------------------------------------------------
package PostScript::Report::FieldTL;
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
# ABSTRACT: A field with a label in the top left corner
#---------------------------------------------------------------------

our $VERSION = '0.10';
# This file is part of PostScript-Report 0.13 (November 30, 2013)

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);


has label => (
  is      => 'ro',
  isa     => Str,
  default => '',
);


has label_font => (
  is  => 'ro',
  isa => FontObj,
  traits   => [ TreeInherit => {
    fetch_method => 'get_style',
    default      => sub { shift->report->get_font(Helvetica => 6) },
  } ],
);

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);


has multiline => (
  is       => 'ro',
  isa      => Bool,
);

has padding_side => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);

sub padding_label_side { shift->padding_side }
sub padding_text_side  { shift->padding_side }
sub padding_label_top { 0 }
sub padding_text_top  { 0 }

after init => sub {
  my ($self, $parent, $report) = @_;

  $report->ps->use_functions(qw(clipBox showCenter showLeft showRight));

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'FieldTL' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% CONTENT... Csp Cx Cy DISPLAYFUNC LINES CONTENTFONT LABEL Lx Ly L T R B LABELFONT FieldTL
% Leaves on stack: L T R B

/FieldTL
{
  gsave
  setfont
  4 copy clipBox	% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B
  3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B L
  7 -1 roll add		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX
  3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX T
  7 -1 roll sub		% C... Csp Cx Cy FUNC LINES CF LABEL L T R B LblX LblY
  7 -1 roll showLeft	% C... Csp Cx Cy FUNC LINES CF L T R B
  5 -1 roll setfont	% C... Csp Cx Cy FUNC LINES L T R B
  2 index		% C... Csp Cx Cy FUNC LINES L T R B T
  8 -1 roll sub		% C... Csp Cx FUNC LINES L T R B Ypos
  4 index		% C... Csp Cx FUNC LINES L T R B Ypos L
  3 index		% C... Csp Cx FUNC LINES L T R B Ypos L R
  3 -1 roll		% C... Csp Cx FUNC LINES L T R B L R Ypos
  8 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos LINES
  {			% C... Csp Cx FUNC L T R B L R Ypos
    3 copy		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos
    14 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos CONTENT
    4 2 roll		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R
    12 index		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R Cx
    12 index cvx exec	% C... Csp Cx FUNC L T R B L R Ypos
    9 index sub		% C... Csp Cx FUNC L T R B L R YposNext
  } repeat
  pop pop pop		% Csp Cx FUNC L T R B
  7 -3 roll		% L T R B Csp Cx FUNC
  pop pop pop		% L T R B
  grestore
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-C {
  pop                   % Y CONTENT L R
  add 2 div             % Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showCenter
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-L {
  exch pop add		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showLeft
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-R {
  sub exch pop		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showRight
} def
END PS
};

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my @lines = $rpt->get_value($self->value);

  my $FieldTL   = $self->id;
  my $font      = $self->font;
  my $labelFont = $self->label_font;
  my $labelSize = $labelFont->size;

  if ($self->multiline) {
    @lines = $font->wrap($self->width - 1.5 * $self->padding_text_side,
                         @lines);
  } # end if multiline

  my $ps = $rpt->ps;
  $ps->add_to_page( sprintf(
    "%s\n%s %s %s /%s-%s %d %s\n%s\n%s %s %d %d %d %d %s %s %s db%s\n",
    join("\n", map { $ps->pstr($_) } reverse @lines),
    $font->size,
    $self->padding_text_side,
    $font->size + $self->padding_label_top+$labelSize + $self->padding_text_top,
    $FieldTL, uc substr($self->align, 0, 1),
    scalar @lines,
    $font->id,
    $ps->pstr($self->label),
    $self->padding_label_side,
    $labelSize + $self->padding_label_top,
    $x, $y, $x + $self->width, $y - $self->height,
    $labelFont->id,
    $FieldTL,
    $self->line_width, $self->border,
  ));
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::FieldTL - A field with a label in the top left corner

=head1 VERSION

This document describes version 0.10 of
PostScript::Report::FieldTL, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is a text field
with a label in the upper left corner.

Note that FieldTL does not have or use the C<padding_bottom>
attribute.  Instead, the label text is placed at the top of the field,
and the value text right below that.

=head1 ATTRIBUTES

A FieldTL has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_side>, and C<value>, plus the following:

=for Pod::Coverage
draw
padding_.*


=head2 label

This string is the label to print in the corner.


=head2 label_font

This is the font used to draw the label.  It defaults to Helvetica 6.
The value may be inherited.


=head2 multiline

If true, the value will be wrapped onto multiple lines based on the
width of the component.  If the value is too long, it will be cropped
at the bottom.  If a word is too long for a single line, it will be cropped.

If false, (the default) then the value will be printed on a single
line (and cropped if it is too long).

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

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
