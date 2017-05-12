use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 4;

use_ok('Monitoring::TT');
use_ok('Monitoring::TT::Input::Nagios');

##################################################
# set it twice to avoid 'used only once:' warning
$Monitoring::TT::Log::Verbose = 0;
$Monitoring::TT::Log::Verbose = 0;
my $montt     = Monitoring::TT->new();
my $nag       = Monitoring::TT::Input::Nagios->new(montt => $montt);
my $types     = $nag->get_types(['t/data/111-input_nagios']);
my $types_exp = ['hosts'];
is_deeply($types, $types_exp, 'nagios input types') or diag(Dumper($types));

my $hosts     = $nag->read('t/data/111-input_nagios', 'hosts');
my $hosts_exp =  [{
            'name'                  => 'test-win',
            'address'               => '127.0.0.2',
            'alias'                 => '',
            'groups'                => [],
            'type'                  => 'windows',
            'apps'                  => {},
            'tags'                  => {},
            'conf'                  => {
                    '_some_other_cust_var'  => 'foo',
                    'use'                   => 'generic-host',
                    'host_name'             => 'test-win',
                    'address'               => '127.0.0.2',
                    'contact_groups'        => 'test-contact',
            },
            'file'                  => 't/data/111-input_nagios/hosts-win.cfg',
            'line'                  => '1',
          },
          {
            'name'                  => 'test-host',
            'address'               => '127.0.0.1',
            'alias'                 => '',
            'apps'                  => {
                    'database'          => '',
                    'webserver'         => ''
                      },
            'tags'                  => {
                    'debian'            => '',
                    'https'             => '',
                    'http'              => '80',
                      },
            'groups'                => [],
            'type'                  => 'linux',
            'conf'                  => {
                    'use'               => 'generic-host',
                    'host_name'         => 'test-host',
                    'address'           => '127.0.0.1',
                    'contact_groups'    => 'test-contact',
            },
            'file'                  => 't/data/111-input_nagios/hosts.cfg',
            'line'                  => '1',
          }
        ];
is_deeply($hosts, $hosts_exp, 'input parser') or diag(Dumper($hosts));
