package Siebel::COM::Exception::DataServer;

use warnings;
use strict;
use Win32::OLE::Variant;
use Moose::Role 2.1604;
our $VERSION = '0.3'; # VERSION

has 'return_code' => (
    is      => 'ro',
    isa     => 'Win32::OLE::Variant',
    builder => '_build_variant',
    reader  => 'get_return_code'
);

sub check_error {

    my $self = shift;

    unless ( $self->get_return_code() == 0 ) {

        my $msg = Win32::OLE->LastError();
        die "The method returned an exception: $msg";

    }

}

sub _build_variant {

    return Variant( VT_I2 | VT_BYREF, 0 );

}

1;

__END__

=head1 NAME

Siebel::COM::Exception::DataServer - Moose role to apply proper error checking for Siebel COM DataServer

=head1 SYNOPSIS

  use Moose;
  
  with 'Siebel::COM::Exception::DataServer';

=head1 DESCRIPTION

This is a Moose Role to implement proper error checking for classes based on Siebel COM DataServer.

=head2 EXPORT

None by default.

=head2 ATTRIBUTES

=head3 return_code

An reference to a L<Win32::OLE::Variant> object. It is used check and maintain return codes for almost all method invocation done
by classes that uses Siebel::COM::Exception::DataServer.

=head2 METHODS

=head3 get_return_code

Returns the C<return_code> attribute value.

=head3 check_error

Checks the attribute value of C<return_code> attribute. If it is different from zero, an exception will be raised with C<die>.

The message used by C<die> will contain the C<return_code> value plus the error message associated.

=head1 SEE ALSO

=over

=item *

L<Win32::OLE::Variant>

=item *

L<Siebel::COM::App::DataServer>

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

