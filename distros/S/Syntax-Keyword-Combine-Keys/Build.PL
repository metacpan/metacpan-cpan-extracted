use v5;
use strict;
use warnings;
 
use Module::Build;
use XS::Parse::Keyword::Builder;
 
my $build = Module::Build->new(
   module_name => "Syntax::Keyword::Combine::Keys",
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
      'XS::Parse::Keyword::Builder' => '0.08',
   },
   requires => {
      'perl' => '5.014',
      'XS::Parse::Keyword' => '0.08',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
   extra_compiler_flags => [qw( -Ihax )],
);
 
XS::Parse::Keyword::Builder->extend_module_build( $build );
 
$build->create_build_script;
