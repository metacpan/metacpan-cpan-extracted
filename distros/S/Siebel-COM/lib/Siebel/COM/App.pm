package Siebel::COM::App;

use strict;
use Win32::OLE 0.17;
use Moose 2.1604;
use MooseX::FollowPBP 0.05;
use Siebel::COM::Business::Object;
use Siebel::COM::Business::Object::DataServer;
use namespace::autoclean 0.25;

with 'Siebel::COM';

our $VERSION = '0.3'; # VERSION

has 'user'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'password'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'ole_class' => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILD {

    my $self = shift;

    my $app = Win32::OLE->new( $self->get_ole_class() )
      or confess( 'failed to load ' . $self->get_ole_class() . ': ' . $! );

    Win32::OLE->Option( Warn => 3 );

    $self->_set_ole($app);

}

sub login {

    my $self = shift;

    $self->get_ole()->Login( $self->get_user(), $self->get_password() );

}

sub get_bus_object {

    my $self    = shift;
    my $bo_name = shift;

    my $bo = Siebel::COM::Business::Object->new(
        { '_ole' => $self->get_ole()->GetBusObject($bo_name) } );

    return $bo;

}

sub get_last_error {

    my $self = shift;

    return $self->_error();

}

1;
__END__

=head1 NAME

Siebel::COM::App - Perl extension to connect to a Siebel application

=head1 SYNOPSIS

  package Siebel::COM::App::DataServer;

  use Moose;
  use namespace::autoclean;

  extends 'Siebel::COM::App';

=head1 DESCRIPTION

Siebel::COM::App is a superclass and cannot be used directly: a subclass is required since it does not provide any connection at all to a Siebel
environment.

As a superclass,  Siebel::COM::App provides:

=over

=item *

proper initialization of subclasses, including default exceptions from L<Win32::OLE>.

=item *

the attributes described in the section ATTRIBUTES.

=item *

the methods described in the section METHODS.

=back

=head2 EXPORT

None by default.

=head2 ATTRIBUTES

All attributes below are required during object creation.

=head3 user

The user login that will be used for authentication when C<login> method is invoked.

=head3 password

The user password that will be used for authentication when C<login> method is invoked.

=head3 ole_class

The class that should be loaded by L<Win32::OLE>. Beware that the class must be registered correctly to be used.

=head2 METHODS

=head3 BUILD

Moose based BUILD method takes care of initializing correctly subclasses of Siebel::COM::App, including changing the warnings from L<Win32::OLE>
to force exceptions by executing C<Win32::OLE->Option( Warn => 3 )>.

=head3 login

Login does, uhn, login at a Siebel application. It expects does not expect any parameter and returns true with success or an exception is raised.

=head3 get_bus_object

Returns a L<Siebel::COM::Business::Object> object (or a subclass of it): expects a Business Object name as a parameter and an exception is raised if the
Business Object definition cannot be found in the SRF.

=head3 get_last_error

Returns the last error message retrieved, including the error message code and message.

=head1 SEE ALSO

=over

=item *

L<Siebel::COM::App::DataServer>

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
