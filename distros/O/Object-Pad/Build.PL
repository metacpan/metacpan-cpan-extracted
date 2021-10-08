use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;
use XS::Parse::Sublike::Builder;

my @extra_compiler_flags = qw( -Iinclude -Ihax );

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

use Config;
if( $Config{ccname} eq "gcc" ) {
   # Enable some extra gcc warnings, largely just for author interest
   push @extra_compiler_flags, qw( -Wall -Wno-unused-function );
}

my $build = Module::Build->new(
   module_name => 'Object::Pad',
   requires => {
      # On perl 5.31.9 onwards we use core's no feature 'indirect',
      ( $] >= 5.031009 ?
         () :
         ( 'indirect' => 0 ) ),

      'perl' => '5.018', # pad_add_name_pvn, pad_add_name_pvs, gv_init_pvn
         # Technically probably would work on 5.16 but doesn't:
         #   https://rt.cpan.org/Ticket/Display.html?id=132930
      'XS::Parse::Keyword' => '0.19',
      'XS::Parse::Sublike' => '0.13',
   },
   test_requires => {
      'Data::Dump' => 0,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.19',
      'XS::Parse::Sublike::Builder' => '0.13',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

XS::Parse::Sublike::Builder->extend_module_build( $build );

if( eval { require Devel::MAT::Dumper::Helper; Devel::MAT::Dumper::Helper->VERSION( '0.41' ) } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

$build->create_build_script;
