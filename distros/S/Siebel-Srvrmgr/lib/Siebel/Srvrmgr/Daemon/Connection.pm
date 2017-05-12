package Siebel::Srvrmgr::Daemon::Connection;

use Moose::Role;

our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Connection - Moose roles for Siebel::Srvrmgr::Daemon subclasses that uses a connection

=head1 DESCRIPTION

This is a L<Moose::Role> to be used by L<Siebel::Srvrmgr::Daemon> subclasses that needs a connection with the Siebel Enterprise.

=head1 ATTRIBUTES

=head1 connection

A reference to a L<Siebel::Srvrmgr::Connection> instance.

This is a read-only, required attribute for classes that applies this L<Moose::Role>.

=cut

has connection => (
    is       => 'Siebel::Srvrmgr::Connection',
    is       => 'ro',
    reader   => 'get_conn',
    required => 1
);

=head1 METHODS

=head2 get_conn

Getter for the C<connection> attribute.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Connection>

=item *

L<Siebel::Srvrmgr::Daemon::Heavy>

=item *

L<Siebel::Srvrmgr::Daemon::Light>

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

1;
