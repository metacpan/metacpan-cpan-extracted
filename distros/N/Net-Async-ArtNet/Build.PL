use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::ArtNet',
   requires => {
      'IO::Async::Loop' => '0.59',
      'IO::Async::Socket' => '0.59',
   },
   test_requires => {
      'IO::Async::Test' => 0,
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
