
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Use Squid rules in Perlbal.",
  "dist_author" => [
    "Ilmari Vacklin <ilmari\@dicole.com>",
    "Antti V\303\244h\303\244kotam\303\244ki <antti\@dicole.com>"
  ],
  "dist_name" => "Perlbal-Plugin-Extredirector",
  "dist_version" => "v0.0.4",
  "license" => "perl",
  "module_name" => "Perlbal::Plugin::Extredirector",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "IPC::Open2" => 0,
    "Net::Netmask" => 0,
    "Perlbal" => 0,
    "Socket" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
