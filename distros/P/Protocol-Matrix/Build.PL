use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Protocol::Matrix',
   requires => {
      'Crypt::NaCl::Sodium' => 0,
      'Digest::SHA' => 0,
      'HTTP::Request' => 0,
      'JSON' => 0,

      'perl' => '5.014', # s///r
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
