package Siebel::COM::Business::Component::DataServer;

use strict;
use Moose 2.1604;
use namespace::autoclean 0.25;
use Siebel::COM::Constants;

extends 'Siebel::COM::Business::Component';
with 'Siebel::COM::Exception::DataServer';
our $VERSION = '0.3'; # VERSION

around 'activate_field' => sub {

    my $orig       = shift;
    my $self       = shift;
    my $field_name = shift;

    $self->$orig( $field_name, $self->get_return_code() );

    $self->check_error();

};

around 'get_field_value' => sub {

    my $orig       = shift;
    my $self       = shift;
    my $field_name = shift;

    my $value = $self->$orig( $field_name, $self->get_return_code() );

    $self->check_error();

    return $value;

};

around 'clear_query' => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( $self->get_return_code() );
    $self->check_error();

};

around 'set_search_expr' => sub {

    my $orig        = shift;
    my $self        = shift;
    my $search_expr = shift;

    $self->$orig( $search_expr, $self->get_return_code() );
    $self->check_error();

};

around 'set_search_spec' => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( @_, $self->get_return_code() );
    $self->check_error();

};

around 'get_search_spec' => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( @_, $self->get_return_code() );
    $self->check_error();

};

around 'query' => sub {

    my $orig        = shift;
    my $self        = shift;
    my $cursor_type = shift;    # optional parameter

    $cursor_type = FORWARD_ONLY
      unless ( defined($cursor_type) );    # default cursor type

    $self->$orig( $cursor_type, $self->get_return_code() );
    $self->check_error();

};

around 'first_record' => sub {

    my $orig = shift;
    my $self = shift;

    my $boolean = $self->$orig( $self->get_return_code() );

    $self->check_error();
    return $boolean;

};

around 'next_record' => sub {

    my $orig = shift;
    my $self = shift;

    my $boolean = $self->$orig( $self->get_return_code() );
    $self->check_error();
    return $boolean;

};

around 'set_field_value' => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( @_, $self->get_return_code() );
    $self->check_error();

};

around 'write_record' => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( $self->get_return_code() );
    $self->check_error();

};

around 'set_view_mode' => sub {

    my $orig = shift;
    my $self = shift;
    my $mode = shift;

    if ( defined($mode) ) {

        $self->$orig( $mode, $self->get_return_code() );

    }
    else {

        $self->$orig( 3, $self->get_return_code() );

    }

};

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Siebel::COM::Business::Component::DataServer - Business Component class for Siebel COM DataServer

=head1 DESCRIPTION

This class is an extension of L<Siebel::COM::Business::Component> but with the necessary differents to do proper error checking.

You probably will want to instantiate of it by using a L<Siebel::COM::Business::Object::DataServer> instance C<get_bus_comp> method.

This class also applies the role L<Siebel::COM::Exception::DataServer>.

=head2 EXPORT

None by default.

=head2 CONSTANTS

All constants available to the parent class are available too for this class. The following constants are used by default:

=head3 FORWARD_ONLY

If not cursor type parameter is informed to the C<query> method, the value of FORWARD_ONLY is used by default.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::Business::Object::DataServer>

=item *

L<Siebel::COM::App::DataServer>

=item *

L<Siebel::COM::Business::Component>

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
