
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Spark::Form',
  license       => 'perl',
  dist_abstract => "A\ simple\ yet\ powerful\ forms\ validation\ system\ that\ promotes\ reuse\.",
  dist_name     => "Spark\-Form",
  dist_author   => [
"James\ Laver\ L\<http\:\/\/jameslaver\.com\>",
  ],
  requires      => {
    "Module::Pluggable" => '0',
    "MooseX::LazyRequire" => '0.04',
    "Test::More" => '0',
    "List::Util" => '0',
    "Data::Couplet" => '0.02004312',
    "MooseX::AttributeHelpers" => '0.21',
    "List::MoreUtils" => '0',
    "Moose" => '0.89',
    "HTML::Tiny" => '0',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
