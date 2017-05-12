package Siebel::Params::Checker;
use strict;
use warnings;
use Siebel::Srvrmgr::Daemon::Heavy;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams;
use Siebel::Srvrmgr::Daemon::Command;
use Set::Tiny 0.03;
use Siebel::Params::Checker::ListComp;
use Siebel::Params::Checker::ListParams;
use Siebel::Srvrmgr::Util::IniDaemon qw(create_daemon);
use Config::IniFiles 2.88;
use Exporter 'import';
our $VERSION = '0.002'; # VERSION

=pod

=head1 NAME

Siebel::Params::Checker - Perl module to extract and show Siebel component parameters between servers

=head1 DESCRIPTION

This modules provides a interface to a Siebel Enterprise to search and extract parameters from a specific Siebel component from all Siebel Server it is available.

=head1 EXPORTS

The C<recover_info> function is the only one exported by demand.

=cut

our @EXPORT_OK = qw(recover_info);

=head1 FUNCTIONS

=head2 recover_info

This functions connects to the Siebel Enterprise and retrieve the parameters values of the desired component.

It expects as parameters:

=over

=item *

A string of the complete path to a configuration file that is understandle by L<Config::Tiny> (a INI file).

=item *

A compile regular expression with C<qr> that will be use to search which Siebel Server have the desired component configured. The match will be tried at
the component alias.

=back

Check the section "Configuration file" of this Pod for details about how to create and maintain the INI file.

It returns a reference to following data structure:

    { 
        server1 => {
            parameter1 => value1, 
            parameter2 => value2, 
            parameter3 => value3, 
            parameter4 => value4, 
        }, 
        server2 => {
            parameter1 => value1, 
            parameter2 => value2, 
            parameter3 => value3, 
            parameter4 => value4, 
        }, 
        serverN => {
            parameter1 => value1, 
            parameter2 => value2, 
            parameter3 => value3, 
            parameter4 => value4, 
        }, 
    };

All the parameters corresponding to the desired Siebel component.

=cut

sub recover_info {
    my ( $cfg_file, $given_alias ) = @_;
    my $daemon = create_daemon($cfg_file);
    my $cfg    = Config::Tiny->read($cfg_file);
    my $wanted_params =
      Set::Tiny->new( ( split( ',', $cfg->{SEARCH}->{parameters} ) ) );
    my $comp_cmd = "list comp $given_alias";
    chop($comp_cmd);
    $comp_cmd .= '%';

# LoadPreferences does not add anything into ActionStash, so it's ok use a second action here
    $daemon->push_command(
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => $comp_cmd,
                action  => 'Siebel::Params::Checker::ListComp'
            }
        )
    );

    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
    $daemon->run();
    my %data;
    my $servers_ref = $stash->get_stash();
    $stash->set_stash( [] );

    foreach my $server ( @{$servers_ref} ) {
        my $server_comps = $server->get_comps();
        my $server_name  = $server->get_name();
        print "going over $server_name\n";
        $data{$server_name} = {};

        foreach my $comp_alias ( @{$server_comps} ) {
            next unless ( $comp_alias eq $given_alias );
            my $command =
                'list params for server '
              . $server_name
              . ' component '
              . $comp_alias;
            $daemon->set_commands(
                [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        {
                            command => $command,
                            action  => 'Siebel::Params::Checker::ListParams'
                        }
                    )
                ]
            );
            $daemon->run();

            my $params_ref = $stash->shift_stash;

            foreach my $param_alias ( keys( %{$params_ref} ) ) {
                if ( $wanted_params->has($param_alias) ) {
                    $data{$server_name}->{$param_alias} =
                      $params_ref->{$param_alias}->{PA_VALUE};
                }
            }

# :TODO:11/17/2015 07:13:51 PM:: some refactoring is in order since I just copied the logic above and modified a bit
            if ( exists( $cfg->{SEARCH}->{advanced} ) ) {
                my $adv_want = Set::Tiny->new(
                    ( split( ',', $cfg->{SEARCH}->{advanced} ) ) );
                my $command =
                    'list advanced params for server '
                  . $server_name
                  . ' component '
                  . $comp_alias;

# :WORKAROUND:11/17/2015 08:29:42 PM:: See Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams Pod, "Caveats" section
                $daemon->close_child();
                $daemon->set_commands(
                    [
                        Siebel::Srvrmgr::Daemon::Command->new(
                            {
                                command => 'set delimiter |',
                                action  => 'Dummy'
                            }
                        ),
                        Siebel::Srvrmgr::Daemon::Command->new(
                            {
                                command => $command,
                                action  => 'Siebel::Params::Checker::ListParams'
                            }
                        )
                    ]
                );
                $daemon->run();
                my $params_ref = $stash->shift_stash;

                foreach my $param_alias ( keys( %{$params_ref} ) ) {

                    if ( $adv_want->has($param_alias) ) {
                        $data{$server_name}->{$param_alias} =
                          $params_ref->{$param_alias}->{PA_VALUE};
                    }
                }

            }

        }

        delete( $data{$server_name} )
          unless ( keys( %{ $data{$server_name} } ) > 0 );

    }

    return \%data;

}

=head1 CONFIGURATION FILE

The configuration file must have a INI format, which is supported by the L<Config::Tiny> module.

Here is an example of the required parameters with a description:

    [GENERAL]
    # the Siebel Gateway hostname and port, for example
    gateway=foobar:1055
    # the Siebel Enterprise name
    enterprise=MyEnterprise
    # the Siebel user with administrative privileges
    user=sadmin
    # the password from the user with administrative privileges
    password=123456
    # the field delimiter used to separate the output fields of srvrmgr
    field_delimiter=|
    # the complete pathname to the program srvrmgr
    srvrmgr= /foobar/bin/srvrmgr
    [SEARCH]
    # the parameters you want to check the values separated by a comma
    parameters=MaxTasks,MaxMTServers,MinMTServers,BusObjCacheSize
    # the advanced parameters you want to check the values separated by comma
    advanced=MaxSharedDbConns,MinSharedDbConns

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

L<Config::Tiny>

=item *

L<Siebel::Srvrmgr::Util::IniDaemon>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

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
