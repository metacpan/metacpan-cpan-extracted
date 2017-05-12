
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A Perl interface for gandi api",
  "dist_author" => [
    "Natal Ng\303\251tal"
  ],
  "dist_name" => "Net-Gandi",
  "dist_version" => "1.122180",
  "license" => "perl",
  "module_name" => "Net::Gandi",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Const::Fast" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Traits" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::URI" => 0,
    "Params::Check" => 0,
    "XMLRPC::Lite" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
