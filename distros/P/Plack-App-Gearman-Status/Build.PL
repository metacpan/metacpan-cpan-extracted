
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Socket::INET" => 0,
    "Module::Build" => "0.3601",
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::TCP" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Plack application to display the status of Gearman job servers",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "Plack-App-Gearman-Status",
  "dist_version" => "0.001001",
  "license" => "perl",
  "module_name" => "Plack::App::Gearman::Status",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "MRO::Compat" => 0,
    "Net::Telnet::Gearman" => 0,
    "Plack::Component" => 0,
    "Plack::Util::Accessor" => 0,
    "Text::MicroTemplate" => 0,
    "Try::Tiny" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
