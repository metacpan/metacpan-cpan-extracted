
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
    "Test::Class" => 0,
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Access log middleware which creates structured log messages",
  "dist_author" => [
    "Manfred Stock <mstock\@cpan.org>"
  ],
  "dist_name" => "Plack-Middleware-AccessLog-Structured",
  "dist_version" => "0.001000",
  "license" => "perl",
  "module_name" => "Plack::Middleware::AccessLog::Structured",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "DateTime" => 0,
    "JSON" => 0,
    "MRO::Compat" => 0,
    "Net::Domain" => 0,
    "Plack::Middleware" => 0,
    "Plack::Util::Accessor" => 0,
    "Time::HiRes" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
