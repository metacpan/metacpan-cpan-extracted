use strict;
use warnings;
use Module::Build 0.38;
my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.38",
    "Mojolicious::Lite" => 0,
    "Test::Mojo" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "dist_abstract" => "A plugin to make authorization a bit easier",
  "dist_author" => [
    "John Scoles <byterock\@hotmail.com>"
  ],
  "dist_name" => "Mojolicious-Plugin-Authorization",
  "dist_version" => "1.05",
	"license" => "perl",
  "module_name" => "Mojolicious::Plugin::Authorization",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Mojo::Base" => 0
  },
  "script_files" => [],
  "meta_merge" => {
    "resources" => {
      "repository" => 'https://github.com/byterock/mojolicious-plugin-authorization'
    }
  },
);
my $build = Module::Build->new(%module_build_args);
$build->create_build_script;
