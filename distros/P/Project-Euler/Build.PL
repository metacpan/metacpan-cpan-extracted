
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::Most' => '0',
    'autodie' => '0',
    'constant' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Solutions for L<< http://projecteuler.net >>',
  'dist_author' => [
    'Adam Lesperance <lespea@gmail.com>'
  ],
  'dist_name' => 'Project-Euler',
  'dist_version' => '0.20',
  'license' => 'perl',
  'module_name' => 'Project::Euler',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'DateTime' => '0',
    'DateTime::Format::DateParse' => '0',
    'Exporter::Easy' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0',
    'Math::Big::Factors' => '0',
    'Math::BigInt' => '0',
    'Modern::Perl' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Moose' => '0',
    'Readonly' => '0',
    'String::Palindrome' => '0',
    'namespace::autoclean' => '0',
    'perl' => '5.010'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
