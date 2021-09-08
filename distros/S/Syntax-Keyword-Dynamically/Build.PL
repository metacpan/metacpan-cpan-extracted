use v5;
use strict;
use warnings;

use Module::Build;
use XS::Parse::Keyword::Builder;

my $build = Module::Build->new(
   module_name => "Syntax::Keyword::Dynamically",
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.13',
   },
   requires => {
      'perl' => '5.014', # pluggable keywords, XOP
      'XS::Parse::Keyword' => '0.13',
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

if( eval { require Devel::MAT::Dumper::Helper and
            Devel::MAT::Dumper::Helper->VERSION( '0.41' ) } ) {
   Devel::MAT::Dumper::Helper->extend_module_build( $build );
}

XS::Parse::Keyword::Builder->extend_module_build( $build );

# Much cheating
$build->add_property( 'optimize' );
$build->config( optimize => '' );

$build->create_build_script;
