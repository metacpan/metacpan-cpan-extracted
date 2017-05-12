use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

use_ok('Monitoring::TT');
use_ok('Monitoring::TT::Input::Nagios');

##################################################
# set it twice to avoid 'used only once:' warning
$Monitoring::TT::Log::Verbose = 0;
$Monitoring::TT::Log::Verbose = 0;
my $montt     = Monitoring::TT->new();
my $nag       = Monitoring::TT::Input::Nagios->new('montt' => $montt);
my $hosts     = $nag->read('t/data/112-input_nagios-tt', 'hosts');
my $hosts_exp =  [{
            'name'     => 'test-host-1',
            'address'  => '127.0.0.1',
            'alias'    => '',
            'apps'   => {},
            'tags'   => {},
            'groups' => [],
            'type'   => 'linux',
            'conf'   => {
                    'use' => 'generic-host',
                    'host_name' => 'test-host-1',
                    'address' => '127.0.0.1',
                },
            'file'  => 't/data/112-input_nagios-tt/hosts.cfg',
            'line'  => '2',
        }, {
            'name'   => 'test-host-2',
            'address'  => '127.0.0.2',
            'alias'    => '',
            'apps'   => {},
            'tags'   => {},
            'groups' => [],
            'type'   => 'linux',
            'conf'   => {
                    'use' => 'generic-host',
                    'host_name' => 'test-host-2',
                    'address' => '127.0.0.2',
                },
            'file'  => 't/data/112-input_nagios-tt/hosts.cfg',
            'line'  => '2',
        }, {
            'name'   => 'test-host-3',
            'address'  => '127.0.0.3',
            'alias'    => '',
            'apps'   => {},
            'tags'   => {},
            'groups' => [],
            'type'   => 'linux',
            'conf'   => {
                    'use' => 'generic-host',
                    'host_name' => 'test-host-3',
                    'address' => '127.0.0.3',
                },
            'file'  => 't/data/112-input_nagios-tt/hosts.cfg',
            'line'  => '2',
        }];
is_deeply($hosts, $hosts_exp, 'input parser') or diag(Dumper($hosts));
