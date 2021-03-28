use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Parser::MGC',
   requires => {
      'perl' => '5.014',

      'Feature::Compat::Try' => '0',
      'File::Slurp::Tiny' => 0,
      'Scalar::Util' => 0,
   },
   test_requires => {
      'File::Temp' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
