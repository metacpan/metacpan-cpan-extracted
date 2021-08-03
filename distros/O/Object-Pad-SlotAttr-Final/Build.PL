use strict;
use warnings;

use Module::Build;

my @extra_compiler_flags = qw( -Iinclude );

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function );
}

my $build = Module::Build->new(
   module_name => 'Object::Pad::SlotAttr::Final',
   requires => {
      'Object::Pad' => '0.48',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
);

$build->create_build_script;
