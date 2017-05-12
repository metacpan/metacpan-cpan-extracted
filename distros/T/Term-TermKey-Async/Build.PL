use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Term::TermKey::Async',
   requires => {
      'IO::Async' => '0.35',
      'Term::TermKey' => '0.08',
   },
   build_requires => {
      'IO::Async::Loop' => '0.48',
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
