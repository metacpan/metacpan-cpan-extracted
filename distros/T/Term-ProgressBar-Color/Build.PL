
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Provide a progress meter on a standard terminal (with color)",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Term-ProgressBar-Color",
  "dist_version" => "0.00",
  "license" => "perl",
  "module_name" => "Term::ProgressBar::Color",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {},
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
