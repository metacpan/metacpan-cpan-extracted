#---------------------------------------------------------------------
package PostScript::Report::HBox;
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
# ABSTRACT: Hold components in a horizontal row
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Container';

after init => sub {
  my $self = shift;

  my $children = $self->children;

  # Set our height to the tallest child:
  unless ($self->has_height) {
    my $height;

    foreach my $child (@$children) {
      next unless $child->has_height;
      $height = $child->height if ($child->height > ($height || 0));
    }

    $self->_set_height($height) if defined $height;
  } # end unless we have explicit height

  # Set our width to the sum of the children:
  unless ($self->has_width) {
    my $width = 0;

    return if @$children == 1;

    foreach my $child (@$children) {
      die "Children of HBox must have explicit width" unless $child->has_width;
      $width += $child->width;
    }

    $self->_set_width($width);
  } # end unless we have explicit width
}; # end after init

#---------------------------------------------------------------------
sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  foreach my $child (@{ $self->children }) {
    $child->draw($x, $y, $rpt);

    $x += $child->width;
  } # end foreach $child
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::HBox - Hold components in a horizontal row

=head1 VERSION

This document describes version 0.01 of
PostScript::Report::HBox, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This L<Container|PostScript::Report::Role::Container> draws its
children in a horizontal row.  There is no space between children.
If the children are of different heights, their tops are aligned.

=head1 ATTRIBUTES

An HBox has all the normal
L<container attributes|PostScript::Report::Role::Container/ATTRIBUTES>.

If C<height> is not specified, but any child has an explicit height,
then the HBox's height is set to the height of the tallest such child.
Otherwise, the height remains unset.

If C<width> is not specified, then it is set to the sum of the widths
of the child components.  Each child must have an explicit width.

If you specify a width that is more than the sum of the children's
widths, the extra space will appear at the right side of the box.

If you specify a width that is less than the sum of the children's
widths, the children will overflow the right side of the box, which
may lead to components printing on top of each other.

=for Pod::Coverage draw

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
