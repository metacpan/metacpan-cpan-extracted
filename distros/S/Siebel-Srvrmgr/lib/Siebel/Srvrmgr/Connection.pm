package Siebel::Srvrmgr::Connection;

use Moose 2.0401;
use Siebel::Srvrmgr::Types;
use Carp;
our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::Connection - class responsible to provide connection details of a Siebel Enterprise

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Connection;

    my $conn = Siebel::Srvrmgr::Connection->new({ 
        server      => 'servername',
        gateway     => 'gateway',
        enterprise  => 'enterprise',
        user        => 'user',
        password    => 'password',
        bin         => 'c:\\siebel\\client\\bin\\srvrmgr.exe',
        lang_id     => 'PTB', 
        field_delimiter => '|'
    });


=head1 DESCRIPTION

This class holds all the details regarding necessary parameters to connect to a Siebel Enterprise by using srvrmgr.

It should be used by any class that need to do that.

Beware that this class B<does not> hold a connection by itself, only the necessary data to request one. You can share those details, but
not the connection itself.

=head1 ATTRIBUTES

=head2 server

This is a string representing the servername where the instance should connect. This is a optional attribute during
object creation with the C<new> method.

Beware that the C<run> method will verify if the C<server> attribute has a defined value or not: if it has, the C<run>
method will try to connect to the Siebel Enterprise specifying the given Siebel Server. If not, the method will try to connect
to the Enterprise only, not specifying which Siebel Server to connect.

=cut

has server => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 0,
    reader   => 'get_server',
    writer   => 'set_server'
);

=head2 gateway

This is a string representing the gateway where the instance should connect. This is a required attribute during
object creation with the C<new> method.

=cut

has gateway => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_gateway',
    writer   => 'set_gateway'
);

=head2 enterprise

This is a string representing the enterprise where the instance should connect. This is a required attribute during
object creation with the C<new> method.

=cut

has enterprise => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_enterprise',
    writer   => 'set_enterprise'
);

=head2 user

This is a string representing the login for authentication. This is a required attribute during
object creation with the C<new> method.

=cut

has user => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_user',
    writer   => 'set_user'
);

=head2 password

This is a string representing the password for authentication. This is a required attribute during
object creation with the C<new> method.

=cut

has password => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_password',
    writer   => 'set_password'
);

=head2 bin

An string representing the full path to the C<srvrmgr> program in the filesystem.

This is a required attribute during object creation with the C<new> method.

=cut

has bin => (
    isa      => 'NotNullStr',
    is       => 'rw',
    required => 1,
    reader   => 'get_bin',
    writer   => 'set_bin'
);

=head2 lang_id

A string representing the LANG_ID parameter to connect to srvrmgr. If defaults to "ENU";

=cut

has lang_id => (
    isa     => 'Str',
    is      => 'rw',
    reader  => 'get_lang_id',
    writer  => 'set_lang_id',
    default => 'ENU'
);

=head2 field_delimiter

This is a single character attribute. It tells the Daemon class to consider a field delimiter, if such options was
set in the C<srvrmgr> program. If this option is used but this attribute is not set accordinly, parsing will probably
fail.

Since this attribute should be defined during Daemon object instance, it is read-only.

=cut

has field_delimiter => ( is => 'ro', isa => 'Chr', reader => 'get_field_del' );

=head1 METHODS

=head2 get_params

Returns an array reference with all the required parameters to execute srvrmgr program, but the C<password> attribute. See C<get_params_pass> method.

Here is the list of parameters/attributes returned, in this specific order:

=over

=item 1.

bin

=item 2.

enterprise

=item 3.

gateway

=item 4.

user

=item 5.

lang_id

=item 6.

server - if available

=item 7.

field_delimiter - if available

=back

The last two parameters are optional, so they might or not be included, depending on how the object was created.

The C<password> attribute is omitted, in the case the password prompt from srvrmgr is desired to be used.

It is suitable to used directly with C<system> call, avoiding calling the shell (see L<perlsec>).

=cut

sub get_params {
    my $self   = shift;
    my @params = (
        $self->get_bin(),     '/e', $self->get_enterprise(), '/g',
        $self->get_gateway(), '/u', $self->get_user(),       '/l',
        $self->get_lang_id()
    );
    push( @params, '/s', $self->get_server() )
      if ( defined( $self->get_server() ) );
    push( @params, '/k', $self->get_field_del() )
      if ( defined( $self->get_field_del() ) );
    return \@params;
}

=head2 get_params_pass

Returns the same array reference of C<get_params> (in fact, invokes it), with the password included as the last element.

=cut

sub get_params_pass {
    my $self       = shift;
    my $params_ref = $self->get_params;
    push( @{$params_ref}, '/p', $self->get_password );
    return $params_ref;
}

=head2 get_field_del

Getter for the C<field_delimiter> attribute.

=head2 get_lang_id

Returns the value of the attribute C<lang_id>.

=head2 set_lang_id

Sets the attribute C<lang_id>. Expects a string as parameter.

=head2 get_server

Returns the content of C<server> attribute as a string.

=head2 set_server

Sets the attribute C<server>. Expects an string as parameter.

=head2 get_gateway

Returns the content of C<gateway> attribute as a string.

=head2 set_gateway

Sets the attribute C<gateway>. Expects a string as parameter.

=head2 get_enterprise

Returns the content of C<enterprise> attribute as a string.

=head2 set_enterprise

Sets the C<enterprise> attribute. Expects a string as parameter.

=head2 get_user

Returns the content of C<user> attribute as a string.

=head2 set_user

Sets the C<user> attribute. Expects a string as parameter.

=head2 get_password

Returns the content of C<password> attribute as a string.

=head2 set_password

Sets the C<password> attribute. Expects a string as parameter.

=head2 get_bin

Returns the content of the C<bin> attribute.

=head2 set_bin

Sets the content of the C<bin> attribute. Expects a string as parameter.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Daemon>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;

