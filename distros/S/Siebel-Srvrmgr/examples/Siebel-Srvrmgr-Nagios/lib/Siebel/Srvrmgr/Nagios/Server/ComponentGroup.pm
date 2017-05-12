package Siebel::Srvrmgr::Nagios::Server::ComponentGroup;
use XML::Rabbit;

=pod

=head1 NAME

Siebel::Srvrmgr::Nagios::Server::ComponentGroup - Perl extension to represents a Siebel component group instance of the Nagios plugin XML configuration file

=head1 DESCRIPTION

Represents a Siebel component group instance of the Nagios plugin XML configuration file.

=head1 ATTRIBUTES

=head2 name

The name of the component group.

=cut

has_xpath_value 'name'           => './@name', reader => 'get_name';

=head2 defaultOKStatus

A string indicating the expected status for all components that are part of this component group. This is used to setup status for components that do not
have a explicit OKStatus defined in the XML configuration file.

=cut

has_xpath_value 'OKStatus'       => './@defaultOKStatus', reader => 'get_OKStatus';


=head2 defaultTaskOKStatus

A string indicating the expected status for all components tasks that are part of this component group. This is used to setup task status of components that do not
have a explicit TaskOKStatus defined in the XML configuration file.

=cut

has_xpath_value 'taskOKStatus'       => './@defaultTaskOKStatus', reader => 'get_taskOKStatus';

finalize_class();
__END__
=head1 SEE ALSO

=over

=item *

L<XML::Rabbit>

=item *

L<Siebel::Srvrmgr::Nagios::Server::Component>

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
