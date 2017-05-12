package Siebel::Srvrmgr::Nagios::Server;
use XML::Rabbit;

=pod

=head1 NAME

Siebel::Srvrmgr::Nagios::Server - Perl extension to represents a Siebel Server for a Nagios plugin

=head1 DESCRIPTION

This class represents a Siebel Server instance in the XML configuration file of the Nagios plugin.

This class applies the Moose role L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>.

=head1 ATTRIBUTES

=head2 name

The Siebel server name.

=cut

has_xpath_value 'name'             => './@name', reader => 'get_name';

=head2 components

A list of L<Siebel::Srvrmgr::Nagios::Server::Component> instances.

=cut

has_xpath_object_list 'components' => './ns1:components/ns1:component' =>
  'Siebel::Srvrmgr::Nagios::Server::Component', reader => 'get_components';

=head2 componentsGroups

A list of L<Siebel::Srvrmgr::Nagios::ComponentGroup> instances.

=cut

has_xpath_object_list 'componentGroups' =>
  './ns1:componentsGroups/ns1:componentGroup' =>
  'Siebel::Srvrmgr::Nagios::Server::ComponentGroup', reader => 'get_componentGroups';

with 'Siebel::Srvrmgr::Daemon::Action::CheckComps::Server';

finalize_class();

__END__
=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Nagios::Server::Component>

=item *

L<Siebel::Srvrmgr::Nagios::ComponentGroup>

=item *

L<Siebel::Srvrmgr::Daemon::Action::CheckComps::Server>

=item *

L<XML::Rabbit>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
