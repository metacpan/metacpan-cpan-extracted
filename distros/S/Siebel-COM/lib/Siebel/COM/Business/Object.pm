package Siebel::COM::Business::Object;

use strict;
use Moose 2.1604;
use namespace::autoclean 0.25;
use Siebel::COM::Business::Component;

extends 'Siebel::COM::Business';
our $VERSION = '0.3'; # VERSION

sub get_bus_comp {

    my $self    = shift;
    my $bc_name = shift;

    my $bc = Siebel::COM::Business::Component->new(
        { '_ole' => $self->get_ole()->GetBusComp($bc_name) } );

    return $bc;

}

1;
__END__

=head1 NAME

Siebel::COM::Business::Object - Perl extension for Siebel COM Business Object objects

=head1 SYNOPSIS

  sub get_bus_object {

      my $self    = shift;
      my $bo_name = shift;

      my $bo = Siebel::COM::Business::Object->new(
          { '_ole' => $self->get_ole()->GetBusObject($bo_name) } );

      return $bo;

  }

=head1 DESCRIPTION

Siebel::COM::Business::Object represents a Siebel COM Business Object class, but more "perlish".

You probably don't need to use this class directly. Instead, retrieve a instance of it from a instance of L<Siebel::COM::App> subclass.

This class extends L<Siebel::COM::Business>.

=head2 EXPORT

None by default.

=head2 METHODS

=head3 get_bus_comp

Same thing as GetBusComp method from Siebel API, but it returns a L<Siebel::COM::Business::Comp> object.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::App>

=item *

L<Siebel::COM::Business>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

This file is part of Siebel COM project.

Siebel COM is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel COM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel COM.  If not, see <http://www.gnu.org/licenses/>.

=cut
