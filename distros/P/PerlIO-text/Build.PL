
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "Encode" => 0,
    "Errno" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "PerlIO::Layers" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Open a text file portably",
  "dist_author" => [
    "Leon Timmermans <leont\@cpan.org>"
  ],
  "dist_name" => "PerlIO-text",
  "dist_version" => "0.007",
  "license" => "perl",
  "module_name" => "PerlIO::text",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "XSLoader" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
