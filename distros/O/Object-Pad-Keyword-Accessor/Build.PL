use v5;
use strict;
use warnings;

use Module::Build;
use Object::Pad::ExtensionBuilder;
use XS::Parse::Keyword::Builder;

my @extra_compiler_flags;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function );
}

my $build = Module::Build->new(
   module_name => 'Object::Pad::Keyword::Accessor',
   requires => {
      'perl' => '5.022', # intro_my()
      'Object::Pad' => '0.60',
      'XS::Parse::Keyword' => '0.35',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'Object::Pad::ExtensionBuilder' => '0.73',
      'XS::Parse::Keyword::Builder' => '0.35',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
);

Object::Pad::ExtensionBuilder->extend_module_build( $build );

XS::Parse::Keyword::Builder->extend_module_build( $build );

$build->create_build_script;
