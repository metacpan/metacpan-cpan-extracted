use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Prometheus',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'List::Util' => '1.33',
      'Ref::Util' => 0,
      'Struct::Dumb' => 0,
   },
   test_requires => {
      'List::Util'  => '1.29', # pairgrep
      'Test::Fatal' => 0,
      'Test::More'  => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
