use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'String::Tagged::IRC',
   requires => {
      'Convert::Color::RGB8' => 0,
      'Convert::Color::mIRC' => 0,
      'String::Tagged' => '0.11',
      'perl' => '5.010', # //
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
