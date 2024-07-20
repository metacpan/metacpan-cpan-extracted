use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Infix::Builder;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build->new(
   module_name => "Syntax::Operator::Identical",
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Infix::Builder' => '0.44',
   },
   requires => {
      'perl' => '5.014', # pluggable keywords, XOP
      'meta' => '0.003_002',
      'XS::Parse::Infix' => '0.44',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
   extra_compiler_flags => \@extra_compiler_flags,
);

XS::Parse::Infix::Builder->extend_module_build( $build );

$build->create_build_script;
