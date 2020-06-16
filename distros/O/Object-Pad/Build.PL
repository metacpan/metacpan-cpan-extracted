use strict;
use warnings;

use Module::Build;
use XS::Parse::Sublike::Builder;

my $build = Module::Build->new(
   module_name => 'Object::Pad',
   requires => {
      # On perl 5.31.9 onwards we use core's no feature 'indirect',
      ( $] >= 5.031009 ?
         () :
         ( 'indirect' => 0 ) ),

      'perl' => '5.016', # pad_add_name_pvn, pad_add_name_pvs, gv_init_pvn
      'XS::Parse::Sublike' => '0.09',
   },
   test_requires => {
      'Data::Dump' => 0,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Sublike::Builder' => '0.09',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => [qw( -Ihax )],
);

XS::Parse::Sublike::Builder->extend_module_build( $build );

if( eval { require Devel::MAT::Dumper::Helper } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

$build->create_build_script;
