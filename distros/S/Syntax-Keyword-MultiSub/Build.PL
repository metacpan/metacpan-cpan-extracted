use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Sublike::Builder;

my $build = Module::Build->new(
   module_name => "Syntax::Keyword::MultiSub",
   requires => {
      'perl' => '5.026', # parse_subsignature()

      'XS::Parse::Sublike' => '0.15',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Sublike::Builder' => '0.15',
   },
   extra_compiler_flags => [qw( -I. -Ihax -ggdb )],
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

XS::Parse::Sublike::Builder->extend_module_build( $build );

$build->create_build_script;
