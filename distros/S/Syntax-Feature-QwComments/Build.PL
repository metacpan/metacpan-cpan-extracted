#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build qw( );

my $build = Module::Build->new(
   module_name => 'Syntax::Feature::QwComments',
   dist_author => 'Eric Brine <ikegami@adaelis.com>',
   license     => 'CC0_1_0',
   configure_requires => {
      'Module::Build'              => 0.36_14,
      'Software::License::CC0_1_0' => 0,
   },
   build_requires => {
      # For testing only
      # ----------------
      #'Pod::Coverage'      => 0.18,      # Optional.
      'Test::More'          => 0,
      #'Test::Pod'          => 1.22,      # Optional.

      # For developer tests only
      # ------------------------
      #'Test::Pod::Coverage' => 1.08,      # Optional.
   },
   requires => {
      'perl'              => 5.014000,
      'Devel::CallParser' => 0,
      'Lexical::Sub'      => 0,
      'syntax'            => 0.004,
      'version'           => 0,
      'XSLoader'          => 0,
   },
   PL_files => { 'make_call_parser.PL' => 'callparser1.h' },
   add_to_cleanup => [ 'Syntax-Feature-QwComments-*', 'vc100.pdb' ],
   meta_merge => {
      resources => {
         homepage   => 'http://search.cpan.org/dist/Syntax-Feature-QwComments/',
         bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-QwComments',
         repository => "http://github.com/ikegami/perl-Syntax-Feature-QwComments",
      },
   },
);

$build->create_build_script();
