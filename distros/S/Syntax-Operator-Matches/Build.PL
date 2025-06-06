use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Infix::Builder;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build->new(
   module_name => "Syntax::Operator::Matches",
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Infix::Builder' => '0.26',
   },
   requires => {
      'perl' => '5.038', # pluggable keywords, XOP
      'XS::Parse::Infix' => '0.26',
      'match::simple' => '0.012',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_compiler_flags => \@extra_compiler_flags,
);

XS::Parse::Infix::Builder->extend_module_build( $build );
$build->create_build_script;
