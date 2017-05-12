
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Test DNS queries and zone configuration',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Test-DNS',
  'dist_version' => '0.13',
  'license' => 'perl',
  'module_name' => 'Test::DNS',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '0',
    'Net::DNS' => '0',
    'Set::Object' => '0',
    'Test::Builder::Module' => '0',
    'Test::Deep' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
