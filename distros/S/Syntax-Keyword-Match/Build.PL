use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;

my $build = Module::Build->new(
   module_name => "Syntax::Keyword::Match",
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.12',
   },
   requires => {
      'perl' => '5.016', # Perl_do_ncmp(), pad_add_name_pvs()
      'XS::Parse::Keyword' => '0.12',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => [qw( -Iinclude )],
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

$build->create_build_script;
