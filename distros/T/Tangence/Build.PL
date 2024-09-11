use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tangence',
   requires => {
      'perl' => '5.026',
      'meta' => '0.007',
      'Feature::Compat::Try' => 0,
      'Future::AsyncAwait' => '0.47',
      'Object::Pad' => '0.800',
      'Syntax::Keyword::Dynamically' => 0,
      'Syntax::Keyword::Match' => '0.06',

      'Encode' => 0,
      'Exporter' => '5.57',
      'experimental' => 0,
      'Future' => '0.36',
      'List::Util' => '1.29',
      'Parser::MGC' => '0.04',
      'Struct::Dumb' => '0.14', # tests fail on 0.13 or earlier
      'Sub::Util' => '1.40',
   },
   test_requires => {
      'Struct::Dumb' => '0.09',
      'Test::HexString' => 0,
      'Test::More' => '0.88', # done_testing
      'Test2::V0' => '0.000149',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
