use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Term::TermKey',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->use_pkgconfig( "termkey",
   atleast_version => '0.16',
   alien           => "Alien::libtermkey",
   alien_version   => '0.13',
);

$build->create_build_script;
