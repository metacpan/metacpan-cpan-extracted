use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'String::Tagged',
   requires => {
      'perl' => '5.014',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
