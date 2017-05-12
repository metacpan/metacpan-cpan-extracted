
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
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Publish zeroconf data via Avahi",
  "dist_author" => [
    "Ioan Rogers <ioanr\@cpan.org>",
    "Jack Bates <jablko\@cpan.org>"
  ],
  "dist_name" => "Net-Rendezvous-Publish-Backend-Avahi",
  "dist_version" => "0.04",
  "license" => "perl",
  "module_name" => "Net::Rendezvous::Publish::Backend::Avahi",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Net::DBus" => 0,
    "Net::Rendezvous::Publish" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
