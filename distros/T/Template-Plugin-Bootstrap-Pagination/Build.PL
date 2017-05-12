
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Page" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Template" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.94"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Produce HTML suitable for the Bootstrap pagination component",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "Template-Plugin-Bootstrap-Pagination",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "Template::Plugin::Bootstrap::Pagination",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "HTML::Entities" => 0,
    "MRO::Compat" => 0,
    "Scalar::Util" => 0,
    "Template::Exception" => 0,
    "Template::Plugin" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
