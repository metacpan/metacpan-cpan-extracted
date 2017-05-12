package Siebel::Srvrmgr::Nagios::Config;
use XML::Rabbit::Root;
use Carp;
use Config;

add_xpath_namespace 'ns1' =>
  'http://code.google.com/p/siebel-monitoring-tools/';

=pod

=head1 NAME

Siebel::Srvrmgr::Nagios::Config - Perl extension for configuration of Siebel-Srvrmgr Nagios plugin

=head1 DESCRIPTION

This class represents the configuration of the Nagios plugin to monitor Siebel components.

This class is based on L<XML::Rabbit> and represents the "core" of configuration for the Nagios plugin. Since the configuration file is a XML
file, the child nodes have their own classes for representation.

=head1 ATTRIBUTES

=head2 server

The Siebel Server name.

=cut

has_xpath_value 'server' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelServer';

=head2 gateway

The Siebel Gateway hostname.

=cut

has_xpath_value 'gateway' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelGateway';

=head2 enterprise

The Siebel Enterprise name.

=cut

has_xpath_value 'enterprise' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:siebelEnterprise';

=head2 srvrmgrPath

The pathname to the srvrmgr executable.

=cut

has_xpath_value(
    'srvrmgrPath',
    '/ns1:siebelMonitor/ns1:connection/ns1:srvrmgrPath',
    (qw(reader srvrmgrPath writer _set_srvrmgrPath))
);

=head2 srvrmgrBin

The name of the binary executable file of srvrmgr (probably srvrmgr).

=cut

has_xpath_value 'srvrmgrBin' =>
  '/ns1:siebelMonitor/ns1:connection/ns1:srvrmgrExec';

=head2 user

The Siebel user login used for authentication.

=cut

has_xpath_value 'user' => '/ns1:siebelMonitor/ns1:connection/ns1:user';

=head2 password

The Siebel user password used for authentication.

=cut

has_xpath_value 'password' => '/ns1:siebelMonitor/ns1:connection/ns1:password';

=head2 servers

A list of L<Siebel::Srvrmgr::Nagios::Server> class instances.

=cut

has_xpath_object_list 'servers' =>
  '/ns1:siebelMonitor/ns1:servers/ns1:server' =>
  'Siebel::Srvrmgr::Nagios::Server';

=head1 METHODS

=head2 BUILD

Set components status if undefined. See L<Moose> for details of BUILD method.

=cut

sub BUILD {

    my $self = shift;

    if ( $self->srvrmgrPath eq 'sitebin' ) {

        $self->_set_srvrmgrPath( $Config{sitebin} );

    }

    foreach my $server ( @{ $self->servers() } ) {

        my %default_status;
        my %default_task_status;

        foreach my $compGroup ( @{ $server->get_componentGroups() } ) {

            $default_status{ $compGroup->get_name() } =
              $compGroup->get_OKStatus();
            $default_task_status{ $compGroup->get_name() } =
              $compGroup->get_taskOKStatus();

        }

        foreach my $comp ( @{ $server->get_components() } ) {

            if ( $comp->get_OKStatus() eq '' ) {

                if (
                    (
                        exists(
                            $default_status{ $comp->get_componentGroup() }
                        )
                    )
                    and
                    defined( $default_status{ $comp->get_componentGroup() } )
                  )
                {

                    $comp->_set_ok_status(
                        $default_status{ $comp->get_componentGroup() } );

                    $comp->_set_task_status(
                        $default_task_status{ $comp->get_componentGroup() } );

                }
                else {

                    confess 'Undefined value for '
                      . $comp->get_alias() . '->'
                      . $comp->get_componentGroup()
                      . ' in server '
                      . $server->get_name()
                      . ' configuration';

                }

            }

        }

    }

}

finalize_class();

__END__

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::Nagios::Server>

=item *

L<Moose>

=item *

L<XML::Rabbit>

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
