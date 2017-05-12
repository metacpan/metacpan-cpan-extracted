#---------------------------------------------------------------------
package PostScript::Report::Image;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Include an EPS file
#---------------------------------------------------------------------

our $VERSION = '0.06';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use File::Spec ();
use List::Util qw(min);

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);


has file => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  writer   => '_set_file',
);

sub BUILD
{
  my $self = shift;

  # Convert the filename to an absolute path if necessary:
  my $fn = $self->file;

  $self->_set_file( File::Spec->rel2abs($fn) )
      unless File::Spec->file_name_is_absolute($fn);
} # end BUILD

has padding_bottom => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);

has padding_side => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);


has scale => (
  is       => 'ro',
  isa      => Num,
  writer   => '_set_scale',
);

after init => sub {
  my ($self, $parent, $report) = @_;

  unless ($self->has_height and $self->has_width and $self->scale) {
    # Get bounding box from file:
    my $fn = $self->file;
    open(my $in, '<', $fn) or confess "Unable to open $fn: $!";
    defined read($in, my $content, 8192) or confess "Failed to read $fn: $!";

    my ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);

    if (not defined $left
        and $content =~ /^\%\%BoundingBox:\s*\(atend\)/m
        and seek($in, 2, -8192)
        and defined read($in, $content, 8192)) {
      ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);
    } # end if BoundingBox at end

    close $in;

    if (defined $left) {
      my $imgHeight = ($top - $bottom) || 1;
      my $imgWidth  = ($right - $left) || 1;

      my $scale = $self->scale;

      if ($self->has_height) {
        if ($self->has_width) {
          my $actHeight = $self->height - 2 * $self->padding_bottom;
          my $actWidth  = $self->width  - 2 * $self->padding_side;
          $scale ||= min($actHeight / $imgHeight, $actWidth / $imgWidth);
        } else {
          my $actHeight = $self->height - 2 * $self->padding_bottom;
          $scale ||= $actHeight / $imgHeight;
          $self->_set_width(
            int($imgWidth * $scale + 2 * $self->padding_side + 0.5)
          );
        } # end else have height but not width
      } elsif ($self->has_width) {
        my $actWidth = $self->width - 2 * $self->padding_side;
        $scale ||= $actWidth / $imgWidth;
        $self->_set_height(
          int($imgHeight * $scale + 2 * $self->padding_bottom + 0.5)
        );
      } else {
        $scale ||= 1;
        $self->_set_height(
          int($imgHeight * $scale + 2 * $self->padding_bottom + 0.5)
        );
        $self->_set_width(
          int($imgWidth  * $scale + 2 * $self->padding_side + 0.5)
        );
      }

      $self->_set_scale($scale);
    } # end if bounding box

    $self->_set_scale(1) unless $self->scale;
  } # end unless we have height, width, and scale

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'Image' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
/Image-StartEPSF {
  /Image-PreEPS_state save def
  translate
  dup scale
  /Image-dict_stack countdictstack def
  count /Image-ops_count exch def
  userdict begin
  /showpage {} def
  % Reset graphics state to defaults:
  0 setgray
  0 setlinecap
  1 setlinewidth
  0 setlinejoin
  10 setmiterlimit
  [] 0 setdash
  newpath
  % If level != 1 then set strokeadjust and overprint to defaults
  /languagelevel where {
    pop
    languagelevel 1 ne {
      false setstrokeadjust
      false setoverprint
    } if
  } if
} bind def

/Image-EPSFCleanUp {
  count Image-ops_count sub {pop} repeat
  countdictstack Image-dict_stack sub {end} repeat
  Image-PreEPS_state restore
} bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $content = $rpt->ps->embed_document($self->file);

  my $scale = $self->scale;

  my ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);

  if (defined $left) {
    my $actWidth  = ($right - $left) * $scale;

    my $align = $self->align;

    $x += do {
      if    ($align eq 'left')   { $self->padding_side }
      elsif ($align eq 'center') { ($self->width - $actWidth) / 2 }
      else  { $self->width - $self->padding_side - $actWidth }
    };
  } else {
    # Can't find bounding box, so force left alignment:
    $x += $self->padding_side;
    warn "Unable to find BoundingBox for " . $self->file;
  }

  $y += $self->padding_bottom - $self->height;

  $x -= $left   * $scale if $left;
  $y -= $bottom * $scale if $bottom;

  my $Image = $self->id;

  $rpt->ps->add_to_page(
    "$scale $x $y $Image-StartEPSF\n$content$Image-EPSFCleanUp\n"
  );
} # end draw

after draw => \&draw_standard_border;

sub _find_bounding_box
{
  my ($self, $contentRef) = @_;

  $$contentRef =~ /^\%\%BoundingBox:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m;
} # end _find_bounding_box

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::Image - Include an EPS file

=head1 VERSION

This document describes version 0.06 of
PostScript::Report::Image, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> allows you to
include an EPS file in your report.  Most vector-based drawing
programs can save in EPS format.  You can also convert bitmap images
to EPS using a program like ImageMagick (L<http://www.imagemagick.org>),
but vector-based formats will generally give you better quality and
smaller files.

=head1 ATTRIBUTES

An Image has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom> and C<padding_side>.

If you specify C<height> but not C<width> (or vice versa), the missing
attribute is calculated based on the image's size, the attribute you
did provide, and the C<scale>.

If you specify neither C<height> nor C<width>, then both are
calculated based on the image size and the C<scale>.

C<align> controls the horizontal alignment of the image.  (Unless it
was unable to find the BoundingBox of the EPS file, in which case left
alignment is forced.)

=for Pod::Coverage BUILD draw



=head2 file

The name of the file to include.  If you give a relative path, it will
be converted to an absolute path.  Required.


=head2 scale

This is the factor by which the image will be scaled.  If you supply
an explicit C<height> and/or C<width>, but no C<scale>, then the scale
will be calculated to make the image fit in the specified dimensions
(based on the BoundingBox in the EPS file).  Otherwise, the scale
defaults to 1 (actual size).  Numbers greater than 1 make the image larger.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Since it is non-trivial to turn an EPS file into a PostScript
procedure, the image file is included every time the component is
drawn.  This is no problem when the image appears only once in a
report header or footer, but an image in a page header or footer can
significantly increase the file size.

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
