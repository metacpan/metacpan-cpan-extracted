use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tangence',
   requires => {
      'perl' => '5.026',

      'Encode' => 0,
      'Exporter' => '5.57',
      'experimental' => 0,
      'Feature::Compat::Try' => 0,
      'Future' => '0.36',
      'Future::AsyncAwait' => '0.47',
      'List::Util' => '1.29',
      'Object::Pad' => '0.57',
      'Parser::MGC' => '0.04',
      'Struct::Dumb' => 0,
      'Sub::Util' => '1.40',
      'Syntax::Keyword::Dynamically' => 0,
      'Syntax::Keyword::Match' => '0.06',
   },
   test_requires => {
      'Struct::Dumb' => '0.09',
      'Test::Fatal' => '0.006',
      'Test::HexString' => 0,
      'Test::Identity' => 0,
      'Test::Memory::Cycle' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
