
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Moose' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'W3C DateTime format type constraint',
  'dist_author' => [
    'Alex J. G. Burzyński <ajgb@cpan.org>'
  ],
  'dist_name' => 'MooseX-Types-DateTime-W3C',
  'dist_version' => '1.103360',
  'license' => 'perl',
  'module_name' => 'MooseX::Types::DateTime::W3C',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'DateTime' => '0',
    'DateTime::TimeZone' => '1.26',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
