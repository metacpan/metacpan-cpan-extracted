
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Request::Common" => 0,
    "Module::Build" => "0.3601",
    "Plack::Test" => 0,
    "Plack::Util" => 0,
    "Test::Class" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Plack middleware which turns application/json responses into HTML",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "Plack-Middleware-JSON-ForBrowsers",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "Plack::Middleware::JSON::ForBrowsers",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Encode" => 0,
    "HTML::Entities" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "MRO::Compat" => 0,
    "Plack::Middleware" => 0,
    "Plack::Util::Accessor" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
