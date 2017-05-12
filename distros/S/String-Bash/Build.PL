
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601',
    'PadWalker' => '0.99',
    'Regexp::Common' => '0',
    'Scalar::Util' => '1.22'
  },
  'dist_abstract' => 'Parameter expansion in strings',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'String-Bash',
  'dist_version' => '1.110960',
  'license' => 'perl',
  'module_name' => 'String::Bash',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'PadWalker' => '0',
    'Regexp::Common' => '0',
    'Scalar::Util' => '0',
    'Sub::Exporter' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
