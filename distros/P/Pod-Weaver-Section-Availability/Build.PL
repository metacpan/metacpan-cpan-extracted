
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Add an AVAILABILITY pod section",
  "dist_author" => [
    "Marcel Gruenauer <marcel\@cpan.org>",
    "Nigel Metheringham <nigelm\@cpan.org>",
    "Mark Gardner <mjgardner\@cpan.org>",
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Pod-Weaver-Section-Availability",
  "dist_version" => "1.20",
  "license" => "perl",
  "module_name" => "Pod::Weaver::Section::Availability",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Plugin::Bugtracker" => 0,
    "Dist::Zilla::Plugin::Homepage" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Pod::Weaver::Role::Section" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
