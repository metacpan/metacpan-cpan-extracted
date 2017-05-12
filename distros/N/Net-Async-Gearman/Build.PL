use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::Gearman',
   requires => {
      'IO::Async::Stream' => 0,
      'Protocol::Gearman' => '0.03',
   },
   build_requires => {
      'Test::Fatal' => 0,
      'Test::HexString' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small', # since we do active testing here
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
