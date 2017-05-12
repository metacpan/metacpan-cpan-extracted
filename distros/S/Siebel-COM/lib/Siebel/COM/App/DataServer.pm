package Siebel::COM::App::DataServer;

use strict;
use Moose 2.1604;
use namespace::autoclean 0.25;

extends 'Siebel::COM::App';
with 'Siebel::COM::Exception::DataServer';
our $VERSION = '0.3'; # VERSION

has cfg         => ( is => 'rw', isa => 'Str', required => 1 );
has data_source => ( is => 'rw', isa => 'Str', required => 1 );
has ole_class =>
  ( is => 'ro', isa => 'Str', default => 'SiebelDataServer.ApplicationObject' );

sub _error {

    my $self = shift;

    return ('('
          . $self->get_return_code() . '): '
          . $self->get_ole()->GetLastErrText() );

}

sub BUILD {

    my $self = shift;
    $self->load_objects();

}

sub get_app_def {

    my $self = shift;

    my $cfg = $self->get_cfg();

    open( my $read, '<', $cfg )
      or die "could not read cfg file $cfg: $!";
    close($read);

    return $cfg . ',' . $self->get_data_source();

}

sub load_objects {

    my $self = shift;

    my $object =
      $self->get_ole()
      ->LoadObjects( $self->get_app_def(), $self->get_return_code() );
    $self->check_error();
    return $object;

}

override 'login' => sub {

    my $self = shift;

    $self->get_ole()
      ->Login( $self->get_user(), $self->get_password(),
        $self->get_return_code() );

    $self->check_error();

};

sub get_bus_object {

    my $self    = shift;
    my $bo_name = shift;

    my $bo = Siebel::COM::Business::Object::DataServer->new(
        {
            '_ole' => $self->get_ole()
              ->GetBusObject( $bo_name, $self->get_return_code() )
        }
    );

    $self->check_error();

    return $bo;

}

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Siebel::COM::App::DataServer - Perl extension for connecting to a Siebel COM Data Server environment

=head1 SYNOPSIS

   $sa = Siebel::COM::App::DataServer->new(
        {
            cfg         => $cfg,
            data_source => $datasource,
            user        => $user,
            password    => $password
        }
    );

    my ( $bo, $bc, $key, $field, $moreResults );

    $sa->login();

    foreach $key ( keys(%$schema) ) {

        $bo = $sa->get_bus_object($key);
        $bc = $bo->get_bus_comp($key);

        foreach $field ( @{ $schema->{$key} } ) {

            $bc->activate_field($field);

        }

        $bc->clear_query();
        $bc->query();

=head1 DESCRIPTION

Siebel::COM::App::DataServer is a subclass of L<Siebel::COM::App>, providing access to the Siebel COM Data Server environment as well
as additional functionality.

Additionally to all architecture differences from L<Siebel::COM::App::DataControl>, this class have important difference about error treament: all
method calls requires a L<Win32::OLE::Variant> to be passed as a parameter for error checking, so all those procedures are executed internally.

To be able to do that, almost all methods inherited from L<Siebel::COM::App> are overloaded or overrided and a specific role 
(L<Siebel::COM::Exception::DataServer>) is applied.

Usually using L<Siebel::COM::App::DataControl> is preferable since it is faster to load and execute and can multiplex connections to a Siebel
Enterprise, but DataServer still have it's specific uses:

=over

=item 1.

Provides CRUD operations in the Siebel Client local database.

=item 2.

Avoid object restrictions in the Siebel Repository by using a local modified SRF.

=item 3.

Avoid security restrictions applied to the Siebel Enterprise, like firewalls and authentication.

=back

=head2 ATTRIBUTES

=head3 cfg

The complete path to the Siebel application configuration file. Required.

=head3 datasource

The datasource name as described in the file of C<cfg> attribute.

=head3 ole_class

Differently from the superclass, this attributes defaults to "SiebelDataServer.ApplicationObject". You probably don't want to change that, so
this attribute is not required during object creation.

=head3 get_bus_object

Overrided from superclass.

Expects a Business Object name as parameter.

Returns a L<Siebel::COM::Business::Object::DataServer> object. If the Business Object name does not exists in the repository, an exception is raised.

=head2 METHODS

=head3 BUILD

Additionally to the superclass operations, this method will call the C<load_objects> method automatically.

=head3 get_app_def

Returns a string as expected by the LoadObjects COM method from the C<ole_class>. It will validate if the C<cfg> can be read and will raise
and exception in the case it cannot.

=head3 load_objects

Same as COM LoadObjects method, but adding the proper error checking.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::Business::Object::DataServer>

=item *

L<Siebel::COM::App>

=item *

L<Siebel::COM::Exception::DataServer>

=item *

L<Siebel::COM::App::DataControl>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
