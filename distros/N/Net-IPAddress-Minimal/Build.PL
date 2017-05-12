
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'IP string to number and back',
  'dist_author' => [
    'Tamir Lousky <tlousky@cpan.org>',
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Net-IPAddress-Minimal',
  'dist_version' => '0.05',
  'license' => 'perl',
  'module_name' => 'Net::IPAddress::Minimal',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Validate' => '0',
    'Data::Validate::IP' => '0',
    'Exporter' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
