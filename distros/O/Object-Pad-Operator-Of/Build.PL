use v5;
use strict;
use warnings;

use Module::Build;
use Object::Pad::ExtensionBuilder;
use XS::Parse::Infix::Builder;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build->new(
   module_name => "Object::Pad::Operator::Of",
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Object::Pad::ExtensionBuilder' => '0.73',
      'XS::Parse::Infix::Builder' => '0.44',
   },
   requires => {
      'perl' => '5.038', # PL_infix_plugin
      'XS::Parse::Infix::Builder' => '0.44',
   },
   test_requires => {
      'Test2::V0' => 0,
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

Object::Pad::ExtensionBuilder->extend_module_build( $build );

XS::Parse::Infix::Builder->extend_module_build( $build );

$build->create_build_script;
