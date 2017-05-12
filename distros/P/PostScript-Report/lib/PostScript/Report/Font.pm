#---------------------------------------------------------------------
package PostScript::Report::Font;
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
# ABSTRACT: Represents a PostScript font
#---------------------------------------------------------------------

our $VERSION = '0.06';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

has document => (
  is       => 'ro',
  isa      => Report,
  weak_ref => 1,
  required => 1,
);


has font => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);


has id => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);


has size => (
  is       => 'ro',
  isa      => Num,
  required => 1,
);


has metrics => (
  is       => 'ro',
  isa      => FontMetrics,
  handles  => [qw(width wrap)],
  lazy     => 1,
  default  => sub {
    my $self = shift;
    $self->document->ps->get_metrics($self->font, $self->size);
  },
);


# width & wrap are now handled by PostScript::File::Metrics

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::Font - Represents a PostScript font

=head1 VERSION

This document describes version 0.06 of
PostScript::Report::Font, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

PostScript::Report::Font represents a font in a L<PostScript::Report>.
You won't deal directly with Font objects unless you are writing your
own L<Components|PostScript::Report::Role::Component>.

You construct a Font object by calling the report's
L<PostScript::Report/get_font> method.

=head1 ATTRIBUTES

=head2 font

This is the PostScript name of the font to use.


=head2 id

This is the PostScript identifier for the scaled font (assigned by the
document).


=head2 metrics

This is a L<PostScript::File::Metrics> object providing information
about the dimensions of the font.


=head2 size

This is the size of the font in points.

=head1 METHODS

=head2 width

  $font->width($text)

This returns the width of C<$text> (in points) if it were printed in
this font.  C<$text> should not contain newlines.


=head2 wrap

  @lines = $font->wrap($width, $text)

This wraps C<$text> into lines of no more than C<$width> points.  If
C<$text> contains newlines, they will also cause line breaks.

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::Report::Font requires no configuration files or environment variables.

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
