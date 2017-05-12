use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'Net::DPAP::Client',
  requires    => {
    'Carp::Assert' => 0,
    'Class::Accessor::Fast' => 0,
    'LWP::Simple' => 0,
    'Net::DAAP::DMAP' => "1.20",
    'URI' => 0,
  },
);
$build->create_build_script;
