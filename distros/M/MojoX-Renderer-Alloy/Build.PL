
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Base class for Template::Alloy renderer",
  "dist_author" => [
    "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>"
  ],
  "dist_name" => "MojoX-Renderer-Alloy",
  "dist_version" => "1.121150",
  "license" => "perl",
  "module_name" => "MojoX::Renderer::Alloy",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Mojolicious" => "2.89",
    "Template::Alloy" => "1.013"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
