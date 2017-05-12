#---------------------------------------------------------------------
package PostScript::Report::Field;
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
# ABSTRACT: A simple field with no label
#---------------------------------------------------------------------

our $VERSION = '0.10';
# This file is part of PostScript-Report 0.13 (November 30, 2013)

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);

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

after init => sub {
  my ($self, $parent, $report) = @_;

  $report->ps->use_functions(qw(clipBox showCenter showLeft showRight));

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'Field' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% X Y STRING FONT L T R B Field-X

/Field { gsave  4 copy  clipBox  8 4 roll setfont } bind def
/Field-C { Field showCenter grestore } bind def
/Field-L { Field showLeft   grestore } bind def
/Field-R { Field showRight  grestore } bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $align = uc substr($self->align, 0, 1);

  my $xOff = do {
    if    ($align eq 'C') { $self->width / 2 }
    elsif ($align eq 'R') { $self->width - $self->padding_side }
    else                  { $self->padding_side }
  };

  my $ps = $rpt->ps;
  $ps->add_to_page( sprintf(
    "%s %s\n%s\n%s %d %d %d %d %s-%s %s db%s\n",
    $x + $xOff, $y - $self->height + $self->padding_bottom,
    $ps->pstr( $rpt->get_value($self->value) ),
    $self->font->id,
    $x, $y, $x + $self->width, $y - $self->height,
    $self->id, $align,
    $self->line_width, $self->border,
  ));
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::Field - A simple field with no label

=head1 VERSION

This document describes version 0.10 of
PostScript::Report::Field, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is a simple text field.

Note:  While you may use a Field as a label by giving it a
L<constant value|PostScript::Report::Value::Constant>, it always uses
C<font> to draw the text, not C<label_font>.

=head1 ATTRIBUTES

A Field has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom>, C<padding_side>, and C<value>.

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
