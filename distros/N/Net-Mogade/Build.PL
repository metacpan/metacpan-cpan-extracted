
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Perl Wrapper for the mogade.com leaderboard/scores service",
  "dist_author" => [
    "Gavin Mogan <gavin\@kodekoan.com>"
  ],
  "dist_name" => "Net-Mogade",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "Net::Mogade",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Digest::SHA1" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Request::Common" => 0,
    "JSON::Any" => 0,
    "LWP::ConnCache" => 0,
    "LWP::UserAgent" => 0,
    "Params::Validate" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
