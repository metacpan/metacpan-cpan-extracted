
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "OX" => 0,
    "Plack::Test" => 0,
    "Test::More" => 0,
    "Test::Path::Router" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "OX::RouteBuilder which routes to an action method in a controller class based on HTTP verbs",
  "dist_author" => [
    "Thomas Klausner <domm\@cpan.org>",
    "Validad GmbH http://validad.com"
  ],
  "dist_name" => "OX-RouteBuilder-REST",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "OX::RouteBuilder::REST",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "OX::RouteBuilder" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
