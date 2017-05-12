
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::File" => 0,
    "Module::Build" => "0.3601",
    "Pod::Coverage::Moose" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "XMLSchema compatible Moose types library",
  "dist_author" => [
    "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>"
  ],
  "dist_name" => "MooseX-Types-XMLSchema",
  "dist_version" => "0.06",
  "license" => "perl",
  "module_name" => "MooseX::Types::XMLSchema",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "DateTime::Duration" => 0,
    "DateTime::TimeZone" => 0,
    "Encode" => 0,
    "IO::Handle" => 0,
    "MIME::Base64" => 0,
    "Math::BigFloat" => 0,
    "Math::BigInt" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Regexp::Common" => 0,
    "URI" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
