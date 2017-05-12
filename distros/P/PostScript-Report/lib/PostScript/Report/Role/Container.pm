#---------------------------------------------------------------------
package PostScript::Report::Role::Container;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 12, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: A component that has components
#---------------------------------------------------------------------

our $VERSION = '0.07';

use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Int Num Str);
use PostScript::Report::Types ':all';

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);


has extra_styles => (
  is       => 'ro',
  isa      => HashRef,
);


has children => (
  traits    => ['Array'],
  is        => 'ro',
  isa       => ArrayRef[Component],
  default   => sub { [] },
  handles  => {
    add_child => 'push',
  },
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


has row_height => (
  is        => 'ro',
  isa       => Int,
  @inherited,
);


after draw => \&draw_standard_border;


after init => sub {
  my ($self, $parent, $report) = @_;

  $_->init($self, $report) for @{ $self->children };
}; # end after init


sub get_style
{
  my ($self, $attribute) = @_;

  # See if we have the attribute:
  my $styles = $self->extra_styles;

  return $styles->{$attribute} if $styles and exists $styles->{$attribute};

  # We don't have it, ask our parent:
  my $parent = $self->parent;
  return ($parent ? $parent->get_style($attribute) : undef);
} # end get_style

#=====================================================================
# Package Return Value:

undef @inherited;
1;

__END__

=head1 NAME

PostScript::Report::Role::Container - A component that has components

=head1 VERSION

This document describes version 0.07 of
PostScript::Report::Role::Container, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This role describes a L<Component|PostScript::Report::Role::Component>
that contains other Components.

=head1 ATTRIBUTES


In addition to the
L<standard attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
a Container provides the following:

=head2 Inherited Attributes

These attributes are provided so that child components can inherit
them.  They have no effect on the container itself.
L<PostScript::Report::Role::Component/"Optional Attributes">.

=over

=item padding_bottom

=item padding_side

=back

=head2 Other Attributes



=head3 children

This is an arrayref containing the child Components.


=head3 extra_styles

This is a hash of additional attributes that can be inherited by child
Components.  You wouldn't normally set this directly, because
L<PostScript::Report::Builder> will automatically move any unknown
attributes into this hash.


=head3 row_height

(Inherited) This is used by VBoxes to set the height of children that
don't specify their own height.  L<PostScript::Report::VBox>.

=head1 METHODS

=head2 draw

The Container role provides an C<after draw> modifier to draw a border
around the container.  The container must still provide its own
C<draw> method.


=head2 get_style

  $parent->get_style($attribute)

Child Components call this method to get the inherited value of any
non-standard style attribute.


=head2 init

The Container role provides an C<after init> modifier that calls
C<init> on each child Component.

=head1 SEE ALSO

The following containers are available by default:

=over

=item L<HBox|PostScript::Report::HBox>

This draws its children in a horizontal row.

=item L<VBox|PostScript::Report::VBox>

This draws its children in a vertical column.

=back

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
