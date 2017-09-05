#!perl

use 5.020;
use Module::Build;

my $build = Module::Build->new(
  dist_name         => 'Spp',
  license           => 'perl',
  dist_author       => q{Micheal.Song <perlvim@gmail.com>},
  dist_version_from => 'lib/Spp.pm',
  build_requires => {
    'Test::More' => 0,
  },
  configure_requires => { 'Module::Build' => 0.42 },
  requires => { 
    'perl' => 5.012,
    'JSON::XS' => 0,
    'List::MoreUtils' => 0,
  },
  add_to_cleanup  => [ 'Spp-*' ],
  script_files    => ['bin/spp'],
  create_makefile_pl => 'traditional',
);

$build->create_build_script();
