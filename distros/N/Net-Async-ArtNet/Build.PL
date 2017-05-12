use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::ArtNet',
   requires => {
      'IO::Async::Loop' => '0.59',
      'IO::Async::Socket' => '0.59',
   },
   build_requires => {
      'IO::Async::Test' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
