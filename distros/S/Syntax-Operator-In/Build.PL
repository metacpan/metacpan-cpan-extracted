use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Infix::Builder;

my $build = Module::Build->new(
   module_name => "Syntax::Operator::In",
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Infix::Builder' => '0.16',
   },
   requires => {
      'perl' => '5.014', # pluggable keywords, XOP
      'XS::Parse::Infix' => '0.16',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => [qw( -I. -Ihax )],
);

XS::Parse::Infix::Builder->extend_module_build( $build );

$build->create_build_script;
