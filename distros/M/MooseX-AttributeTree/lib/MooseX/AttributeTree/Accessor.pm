#---------------------------------------------------------------------
package MooseX::AttributeTree::Accessor;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 9, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Moose accessor role for inheritance through the object tree
#---------------------------------------------------------------------

our $VERSION = '0.06'; # VERSION
# This file is part of MooseX-AttributeTree 0.06 (June 27, 2015)

use MooseX::Role::Parameterized;

parameter qw(parent_link
  is       ro
  isa      Str
  required 1
);

parameter qw(fetch_method
  is       ro
  isa      Maybe[Str]
  required 1
);

parameter qw(default
  is       ro
  isa      Maybe[Value|CodeRef]
  required 1
);

role {
  my $parent_link  = $_[0]->parent_link;
  my $fetch_method = $_[0]->fetch_method;
  my $default      = $_[0]->default;

  # I haven't created inline versions of the methods yet:
  method 'is_inline' => sub { 0 };

  method '_generate_accessor_method' => sub {
    my $attr = (shift)->associated_attribute;
    my ($method, @args) = $fetch_method
        ? ($fetch_method, $attr->name)
        : ($attr->get_read_method);

    return sub {
      $attr->set_value($_[0], $_[1]) if scalar(@_) == 2;

      if ($attr->has_value($_[0])) {
        return $attr->get_value($_[0]);
      } else {
        my $result;
        if (my $parent = $_[0]->$parent_link) {
          $result = $parent->$method(@args);
        } # end if $parent
        return (defined $result ? $result :
                ref $default ? $_[0]->$default : $default);
      } # end else this object has no value for the attribute
    } # end anonymous accessor sub
  }; # end _generate_accessor_method

  method '_generate_reader_method' => sub {
    my $attr = (shift)->associated_attribute;
    my ($method, @args) = $fetch_method
        ? ($fetch_method, $attr->name)
        : ($attr->get_read_method);

    return sub {
      $attr->throw_error('Cannot assign a value to a read-only accessor',
                         data => \@_) if @_ > 1;

      if ($attr->has_value($_[0])) {
        return $attr->get_value($_[0]);
      } else {
        my $result;
        if (my $parent = $_[0]->$parent_link) {
          $result = $parent->$method(@args);
        } # end if $parent
        return (defined $result ? $result :
                ref $default ? $_[0]->$default : $default);
      } # end else this object has no value for the attribute
    } # end anonymous reader sub
  }; # end _generate_reader_method

}; # end role

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

MooseX::AttributeTree::Accessor - Moose accessor role for inheritance through the object tree

=head1 VERSION

This document describes version 0.06 of
MooseX::AttributeTree::Accessor, released June 27, 2015
as part of MooseX-AttributeTree version 0.06.

=head1 DESCRIPTION

MooseX::AttributeTree::Accessor is the backend that does the work for
the C<TreeInherit> trait.  See L<MooseX::AttributeTree> for details.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-MooseX-AttributeTree AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-AttributeTree >>.

You can follow or contribute to MooseX-AttributeTree's development at
L<< https://github.com/madsen/moosex-attributetree >>.

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
