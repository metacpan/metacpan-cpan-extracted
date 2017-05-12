
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Basename' => '0',
    'File::Slurp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'The simplest, stupidest \'pod parser\' possible',
  'dist_author' => [
    'Stephen R. Scaffidi <sscaffidi@cpan.org>'
  ],
  'dist_name' => 'Pod-Stupid',
  'dist_version' => '0.005',
  'license' => 'perl',
  'module_name' => 'Pod::Stupid',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Data::Dumper' => '0',
    'English' => '0',
    'Scalar::Util' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
