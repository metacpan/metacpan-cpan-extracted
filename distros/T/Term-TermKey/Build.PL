use v5;
use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Term::TermKey',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.014',
   },
   test_requires => {
      'Test2::V0' => '0.000149',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_compiler_flags => [qw( -Ihax )],
);

$build->use_pkgconfig( "termkey",
   atleast_version => '0.16',
   alien           => "Alien::libtermkey",
   alien_version   => '0.13',
);

$build->create_build_script;
