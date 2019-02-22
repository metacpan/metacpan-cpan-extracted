use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Term::VTerm',
   test_requires => {
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->use_pkgconfig( "vterm" );

$build->create_build_script;
