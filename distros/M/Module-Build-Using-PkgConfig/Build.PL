use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Module::Build::Using::PkgConfig',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,

      'perl' => '5.010', # //
   },
   test_requires => {
      'Test::More'  => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
