package Siebel::COM::Business::Object::DataServer;

use strict;
use Moose 2.1604;
use namespace::autoclean 0.25;
use Siebel::COM::Business::Component::DataServer;

extends 'Siebel::COM::Business::Object';
with 'Siebel::COM::Exception::DataServer';
our $VERSION = '0.3'; # VERSION

 # :TODO      :06/02/2013 12:31:48:: maybe a new parameter named classname would do in the parent class? with that, a proper around could be used
sub get_bus_comp {

    my $self      = shift;
    my $comp_name = shift;

    my $bc = Siebel::COM::Business::Component::DataServer->new(
        {
            '_ole' => $self->get_ole()
              ->GetBusComp( $comp_name, $self->get_return_code() )
        }
    );

    $self->check_error();

    return $bc;

}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Siebel::COM::Business::Object::DataServer - Business Object class for Siebel COM DataServer

=head1 DESCRIPTION

This class is an extension of L<Siebel::COM::Business::Object> but with the necessary differents to do proper error checking.

You probably will want to instantiate of it by using a L<Siebel::COM::App::DataServer> instance C<get_bus_object> method.

This class also applies the role L<Siebel::COM::Exception::DataServer>.

=head2 EXPORT

None by default.

=head2 METHODS

=head3 get_bus_comp

Same thing then parent class C<get_bus_comp> method, but with added error checking without any change to the interface.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::Business::Object>

=item *

L<Siebel::COM::App::DataServer>

=item *

L<Siebel::COM::Exception::DataServer>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
