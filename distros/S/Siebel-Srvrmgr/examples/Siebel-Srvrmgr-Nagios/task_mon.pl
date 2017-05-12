use warnings;
use strict;
use Siebel::Srvrmgr::Daemon::Light;
use File::Spec::Functions qw(tmpdir catfile);
use Nagios::Plugin;
use Siebel::Srvrmgr::Daemon::ActionStash;
use Siebel::Srvrmgr::Nagios::Config;
use Siebel::Srvrmgr::Daemon::Command;
use Siebel::Srvrmgr::Nagios;

#    COPYRIGHT AND LICENCE
#
#    This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, arfreitas@cpan.org
#
#    This file is part of Siebel Monitoring Tools.
#
#    Siebel Monitoring Tools is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Siebel Monitoring Tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

my $np = Nagios::Plugin->new(
    shortname => 'STM',
    usage     => "Usage: %s -w -c -f",
    version   => $Siebel::Srvrmgr::Nagios::VERSION
);

$np->add_arg(
    spec     => "warning|w=i",
    required => 1,
    help =>
"-w, --warning=INTEGER. Warning if warning threshold is higher than INTEGER",
);

$np->add_arg(
    spec     => "critical|c=i",
    required => 1,
    help =>
"-c, --critical=INTEGER. Critical if critical threshold is higher than INTEGER",
);

$np->add_arg(
    spec     => "configuration|f=s",
    required => 1,
    help     => "-f, --configuration=PATH",
);

$np->getopts();

my $stash;
my $cfg;
my $comps;

eval {

    $cfg =
      Siebel::Srvrmgr::Nagios::Config->new(
        file => $np->opts->configuration() );
		
    die 'siebelServer element requires a non-empty value in XML configuration file' unless ( $cfg->server() ne '' );

    my $daemon = Siebel::Srvrmgr::Daemon::Light->new(
        {
            gateway     => $cfg->gateway(),
            enterprise  => $cfg->enterprise(),
            user        => $cfg->user(),
            password    => $cfg->password(),
            server      => $cfg->server(),
            bin         => catfile( $cfg->srvrmgrPath(), $cfg->srvrmgrBin() ),
            commands    => [
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'load preferences',
                    action  => 'LoadPreferences',
                ),
                Siebel::Srvrmgr::Daemon::Command->new(
                    command => 'list tasks',
                    action  => 'CheckTasks',
                    params  => $cfg->servers()
                )
            ]
        }
    );

    $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    $daemon->run();
};

$np->nagios_die( 'Could not check tasks state: ' . $@ ) if ($@);

my $status = calc_status( $cfg, $stash );

$np->nagios_die(
    'Could not check tasks state: server or component not found')
  if ( $status == -1 );

my $threshold = $np->set_thresholds(
    warning  => $np->opts->warning(),
    critical => $np->opts->critical()
);

$np->nagios_exit(
    return_code => $np->check_threshold($status),
    message     => 'Components status is ' . $status
);

sub calc_status {

    my $cfg     = shift;
    my $results = shift;

    my $status = 0;

    my $result_data = $results->shift_stash();

    if ( exists( $result_data->{ $cfg->server() } ) ) {

        my $server = $result_data->{ $cfg->server() };

        foreach my $comp_name ( keys( %{$server} ) ) {

     # by convention, each component will have 1 if the status is fine, 0 if not
            unless ( $server->{$comp_name} ) {

                my $servers = $cfg->servers();

                my $comps = $servers->[0]->get_components();

 # :TODO      :04/06/2013 19:14:18:: should check if the returned component has the corresponding component in the configuration
 # and issue a warning if not,  at least
 # looping over the available components is not efficient too
                foreach my $comp ( @{$comps} ) {

                    if ( $comp->get_alias() eq $comp_name ) {

                        $status += $comp->get_criticality();

                    }

                }

            }

        }

    }
    else {

        return -1;

    }

    return $status;

}

