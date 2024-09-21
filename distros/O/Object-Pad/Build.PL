use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;
use XS::Parse::Sublike::Builder;

my @extra_compiler_flags = qw( -Ishare/include -Iinclude -Ihax );

# Perl 5.36 made -std=c99 standard; before then we'll have to request it specially
push @extra_compiler_flags, qw( -std=c99 ) if $^V lt v5.36.0;

push @extra_compiler_flags, qw( -DDEBUGGING=-ggdb3 ) if $^X =~ m|/debugperl|;

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
      'XS::Parse::Keyword' => '0.46',
      'XS::Parse::Sublike' => '0.25',
   },
   test_requires => {
      'Test2::V0' => '0.000148',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.46',
      'XS::Parse::Sublike::Builder' => '0.25',
   },
   share_dir => {
      module => { 'Object::Pad' => [ 'share' ] },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

XS::Parse::Keyword::Builder->extend_module_build( $build );

XS::Parse::Sublike::Builder->extend_module_build( $build );

if( eval { require Devel::MAT::Dumper::Helper and
            Devel::MAT::Dumper::Helper->VERSION( '0.45' ) } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

if( $^X =~ m|/debugperl| ) {
   # We need to tell gcc not to optimise away lots of things we want to see in
   # the debugger. It'd be nice if M::B had a nicer way to do this...
   $build->add_property( 'optimize' );
   $build->config( optimize => '-ggdb3' );
}

$build->create_build_script;
