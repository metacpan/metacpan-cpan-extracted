package Siebel::Srvrmgr::Nagios;

use 5.008009;

our $VERSION = '0.02';

1;
__END__
=head1 NAME

Siebel::Srvrmgr::Nagios - Perl extension for monitoring Siebel environment with Nagios

=head1 DESCRIPTION

Siebel::Srvrmgr::Nagios is only Pod about the distribution.

This distribution includes Perl modules based on L<Siebel::Srvrmgr> API to build a functional Nagios plugin to monitor Siebel Server components.

The distribution itself was created to make it easier to setup the Nagios plugin.

The plugin works by executing C<list comp> commands to a Siebel server, recovering the componentes status and comparing them to a existing list that
have the "expected" (a status that does not indicate an error) for each one of the components available in the server. The rest (the return result)
is given to Nagios for interpretation and everything else is done by Nagios itself.

Please see the README file for details of the files that are part of this distribution.

=head2 EXPORT

None by default.

=head1 CAVEATS

Since this is a proof of concept, the plugin was not optimized for production systems: probably the plugin uses more memory than it is really necessary.

=head1 SEE ALSO

=over

=item *

L<Siebel::Monitor::Nagios::Server>

=item *

L<Siebel::Monitor::Nagios::Config>

=item *

L<Siebel::Srvrmgr::Nagios::Server::Component>

=item *

L<Siebel::Srvrmgr::Nagios::Server::ComponentGroup>

=item *

L<Siebel::Srvrmgr>

=item *

L<Nagios::Plugin>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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
