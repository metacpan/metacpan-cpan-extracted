
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Pod Web Server based on Catalyst and ExtJS",
  "dist_author" => [
    "Moritz Onken <onken\@netcubed.de>"
  ],
  "dist_name" => "Pod-Browser",
  "dist_version" => "1.0.1",
  "license" => "bsd",
  "module_name" => "Pod::Browser",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Catalyst" => 0,
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Controller::POD" => "1.0.0",
    "Catalyst::Engine::HTTP" => 0,
    "Catalyst::Engine::PSGI" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Restarter" => 0,
    "Catalyst::Runtime" => "5.7014",
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "Plack" => 0,
    "Plack::Middleware::Conditional" => 0,
    "Plack::Middleware::ReverseProxy" => 0,
    "Plack::Runner" => 0,
    "Pod::Usage" => 0,
    "YAML::Syck" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "script/pod_browser",
    "script/pod_browser_cgi.pl",
    "script/pod_browser_fastcgi.pl",
    "script/pod_browser_server.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
