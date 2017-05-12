#---------------------------------------------------------------------
package PostScript::ScheduleGrid::Style::Solid;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  5 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Solid background style
#---------------------------------------------------------------------

our $VERSION = '0.05'; # VERSION
# This file is part of PostScript-ScheduleGrid 0.05 (August 22, 2015)

use 5.010;
use Moose;

with 'PostScript::ScheduleGrid::Role::Style';

use PostScript::ScheduleGrid::Types ':all';

use namespace::autoclean;

#=====================================================================


has color => (
  is      => 'ro',
  isa     => Color,
  coerce  => 1,
  default => '0.85',            # light gray
);

has text_color => (
  is      => 'ro',
  isa     => Color,
  coerce  => 1,
  default => '0',               # black
);

#=====================================================================
sub define_style
{
  my ($self, $grid) = @_;

  my $code = <<'END PS';
/$name
{
  $color setColor
  clippath fill
  $text_color setColor
} def
END PS

  $self->_ps_eval(\$code);
  $code;
} # end define_style

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

PostScript::ScheduleGrid::Style::Solid - Solid background style

=head1 VERSION

This document describes version 0.05 of
PostScript::ScheduleGrid::Style::Solid, released August 22, 2015
as part of PostScript-ScheduleGrid version 0.05.

=head1 DESCRIPTION

This L<Style|PostScript::ScheduleGrid::Role::Style> produces a solid
colored background.

=for Pod::Coverage
^define_style$

=head1 ATTRIBUTES

=head2 color

The background color for the cell (default light gray 0.85).


=head2 text_color

The color for the cell's text (default black).

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::ScheduleGrid::Style::Solid requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

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
