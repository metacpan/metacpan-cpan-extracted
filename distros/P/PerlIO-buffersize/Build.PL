
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "PerlIO::Layers" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Set the buffersize of a handle",
  "dist_author" => [
    "Leon Timmermans <leont\@cpan.org>"
  ],
  "dist_name" => "PerlIO-buffersize",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "PerlIO::buffersize",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "XSLoader" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
