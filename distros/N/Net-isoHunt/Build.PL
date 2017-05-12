
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601',
    'Test::More' => '0.94'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Access isohunt.com from Perl',
  'dist_author' => [
    'Alan Haggai Alavi <alanhaggai@alanhaggai.org>'
  ],
  'dist_name' => 'Net-isoHunt',
  'dist_version' => '0.102770',
  'license' => 'perl',
  'module_name' => 'Net::isoHunt',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'URI' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
