use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Sublike::Builder;

my @extra_compiler_flags = qw( -Ihax -Iinclude );

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function );
}

my $build = Module::Build->new(
   module_name => 'Signature::Attribute::Checked',
   requires => {
      'perl' => '5.026', # OP_ARGELEM
      'XS::Parse::Sublike' => '0.19',
   },
   test_requires => {
      'Test2::V0' => '0',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Sublike::Builder' => '0.19',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

XS::Parse::Sublike::Builder->extend_module_build( $build );

$build->create_build_script;
