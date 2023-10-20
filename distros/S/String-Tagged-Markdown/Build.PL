use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'String::Tagged::Markdown',
   requires => {
      'perl' => '5.026', # signatures
      'experimental' => 0,
      'HTML::Entities' => 0,
      'List::Util' => '1.45',
      'String::Tagged' => '0.07',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
