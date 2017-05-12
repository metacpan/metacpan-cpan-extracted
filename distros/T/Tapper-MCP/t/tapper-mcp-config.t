#! /usr/bin/env perl

use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use YAML;

use Tapper::Schema::TestTools;

use Test::More 0.88;
use Test::Deep;
use Data::Dumper;

BEGIN { use_ok('Tapper::MCP::Config'); }


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_xenpreconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $producer = Tapper::MCP::Config->new(2);
isa_ok($producer, "Tapper::MCP::Config", 'Producer object created');

my $config = $producer->create_config(1235);     # expects a port number
is(ref($config),'HASH', 'Config created');

is($config->{preconditions}->[0]->{image}, "suse/suse_sles10_64b_smp_raw.tar.gz", 'first precondition is root image');

cmp_deeply($config->{preconditions},
           supersetof({
                       precondition_type => 'package',
                       filename => "tapperutils/opt-tapper64.tar.gz",
                      },
                      {
                       precondition_type => 'package',
                       filename => 'tapperutils/opt-tapper64.tar.gz',
                       mountpartition => undef,
                       mountfile => '/kvm/images/raw.img'
                      },
                      {
                       'config' => {
                                    'guests' => [
                                                 {
                                                  'exec' => '/usr/share/tapper/packages/mhentsc3/startkvm.pl'
                                                 }
                                                ],
                                    'guest_number' => 0,
                                    'guest_count' => 1
                                   },
                       'precondition_type' => 'prc'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                         'runtime' => '5',
                                                         'program' => '/home/tapper/x86_64/bin/tapper_testsuite_kernbench.sh',
                                                         'timeout' => 36000,
                                                         },
                                                        ],
                                    'total_guests' => 1,
                                    'guest_number' => 1,
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/kvm/images/raw.img'
                      },),
           'Choosen subset of the expected preconditions');

is($config->{installer_stop}, 1, 'installer_stop');


my $info = $producer->mcp_info;
isa_ok($info, 'Tapper::MCP::Info', 'mcp_info');
my @timeout = $info->get_testprogram_timeouts(1);
is_deeply(\@timeout,[36120],'Timeout for testprogram in PRC 1'); # timeout + grace period

$producer = Tapper::MCP::Config->new(3);
$config = $producer->create_config();
is(ref($config),'HASH', 'Config created');
is($config->{preconditions}->[3]->{config}->{max_reboot}, 2, 'Reboot test');

$info = $producer->mcp_info;
isa_ok($info, 'Tapper::MCP::Info', 'mcp_info');
my $timeout = $info->get_boot_timeout(0);
is($timeout, 5, 'Timeout booting PRC 0');


#---------------------------------------------------

$producer = Tapper::MCP::Config->new(4);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

my $expected_grub = qr(timeout 2

title RHEL 5
kernel /tftpboot/stable/rhel/5/x86_64/vmlinuz  console=ttyS0,115200 ks=http://bancroft/autoinstall/stable/rhel/5/x86_64/tapper-ai.ks ksdevice=eth0 noapic tapper_ip=\d{1,3}\.\d{1,3}.\d{1,3}.\d{1,3} tapper_port=\d+ testrun=$config->{test_run} tapper_host=$config->{mcp_host} tapper_environment=test
initrd /tftpboot/stable/rhel/5/x86_64/initrd.img
);

like($config->{installer_grub}, $expected_grub, 'Installer grub set by autoinstall precondition');

cmp_deeply($config->{preconditions},
           supersetof(
                      {
                       precondition_type => 'package',
                       filename => "tapperutils/opt-tapper64.tar.gz",
                       'mountpartition' => undef,
                       'mountfile' => '/kvm/images/raw.img'
                     },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          runtime => '5',
                                                          program => '/home/tapper/x86_64/bin/tapper_testsuite_kernbench.sh',
                                                          timeout => 36000,
                                                         },
                                                        ],
                                    'total_guests' => 1,
                                    'guest_number' => 1,
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/kvm/images/raw.img'
                      },
                      {
                       'config' => {
                                    'guest_number' => 0,
                                    'guests' => [
                                                 {
                                                  'exec' => '/usr/share/tapper/packages/mhentsc3/startkvm.pl'
                                                 }
                                                ],
                                    'guest_count' => 1
                                   },
                       'precondition_type' => 'prc'
                      }),
           'Choosen subset of the expected preconditions');

$producer = Tapper::MCP::Config->new(5);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

is_deeply($config->{preconditions}->[0],
          {
           'mount' => '/',
           'precondition_type' => 'image',
           'partition' => [
                           'testing',
                           '/dev/sda2',
                           '/dev/hda2'
                          ],
           'image' => 'suse/suse_sles10_64b_smp_raw.tar.gz'
          },
          'Partition alternatives');

$producer = Tapper::MCP::Config->new(6);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');

cmp_deeply($config->{preconditions},
           supersetof({'dest'              => '/xen/images/002-uruk-1268101895.img',
                       'name'              => 'osko:/export/image_files/official_testing/windows_test.img',
                       'protocol'          => 'nfs',
                       'precondition_type' => 'copyfile'
                      },
                      {
                       precondition_type => 'package',
                       filename => 'tapperutils/opt-tapper32.tar.gz',
                       mountpartition => undef,
                       'mountfile' => '/xen/images/002-uruk-1268101895.img'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          'runtime'  => '50',
                                                          'program' => '/opt/tapper/bin/metainfo',
                                                          'timeout'  => '300',
                                                          'parameters' => [
                                                                           '--foo=some bar'
                                                                          ],
                                                         },
                                                         {
                                                          'runtime' => '1200',
                                                          'timeout' => '1800',
                                                          'program' => '/opt/tapper/bin/py_kvm_unit'
                                                         }
                                                        ],
                                    'guests'         => [
                                                         {
                                                          'svm'      => '/xen/images//002-uruk-1268101895.svm'
                                                         }
                                                        ],
                                    'guest_number' => 0,
                                    'guest_count'    => 1
                                   },
                       'precondition_type' => 'prc'
                      },
                      {
                       'config' => {
                                    testprogram_list => [
                                                         {
                                                          'runtime' => '28800',
                                                          'program' => '/opt/tapper/bin/py_reaim',
                                                          'timeout' => '36000',
                                                          }
                                                        ],
                                    'total_guests' => 1,
                                    'guest_number' => 1
                                   },
                       'mountpartition' => undef,
                       'precondition_type' => 'prc',
                       'mountfile' => '/xen/images/002-uruk-1268101895.img'
                      },

                     ),
           'Choosen subset of the expected preconditions');

$producer = Tapper::MCP::Config->new(7);

$config = $producer->create_config(1337);   # expects a port number
is(ref($config),'HASH', 'Config created');


cmp_deeply($config->{preconditions},
           supersetof( {
                        'testprogram_list'  => [],
                        'precondition_type' => 'prc',
                        'config'            => {
                                                'guest_number'  => 0,
                                               },
                       }
                     ),
           'PRC installed even without test program(s)');


done_testing();
