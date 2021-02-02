use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => "Syntax::Keyword::Finally",
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.014', # pluggable keywords, XOP
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },

   extra_compiler_flags => [qw( -Ihax )],
);

$build->create_build_script;
