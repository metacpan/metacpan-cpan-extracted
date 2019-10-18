use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Object::Pad',
   requires => {
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => [qw( -Ihax )],
);

$build->create_build_script;
