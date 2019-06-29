use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'POE::Future',
   requires => {
      'Future' => '0.05',
      'POE' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Timer' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
