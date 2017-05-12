
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.4003",
    "Moose" => 0,
    "MooseX::Types::Moose" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4003"
  },
  "dist_abstract" => "Types for emulating Hash-like behaviours with ArrayRefs.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "MooseX-Types-FakeHash",
  "dist_version" => "0.1.2",
  "license" => "perl",
  "module_name" => "MooseX::Types::FakeHash",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose::Meta::TypeConstraint::Parameterizable" => 0,
    "Moose::Meta::TypeConstraint::Parameterized" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
