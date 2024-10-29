use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;

my @extra_compiler_flags = qw( -Ihax );

my $build = Module::Build->new(
   module_name => "Syntax::Keyword::PhaserExpression",
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.13',
   },
   requires => {
      'perl' => '5.018',
      'XS::Parse::Keyword' => '0.13',
   },
   extra_compiler_flags => \@extra_compiler_flags,
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

$build->create_build_script;
