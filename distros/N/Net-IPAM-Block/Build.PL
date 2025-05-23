use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
  module_name        => 'Net::IPAM::Block',
  license            => 'perl_5',
  dist_author        => q{Karl Gaissmaier <karl.gaissmaier(at)uni-ulm.de>},
  dist_version_from  => 'lib/Net/IPAM/Block.pm',
  release_status     => 'stable',
  configure_requires => {
    'Module::Build' => '0.4004',
  },
  test_requires => {
    'Test::More' => '0',
  },
  requires => {
    'perl'            => '5.10.0',
    'List::Util'      => '1.43',
    'Scalar::Util'    => '1.39',
    'Carp'            => '0',
    'Net::IPAM::IP'   => '4.01',
  },
  add_to_cleanup => ['Net-IPAM-Block-*'],
);

$builder->create_build_script();
