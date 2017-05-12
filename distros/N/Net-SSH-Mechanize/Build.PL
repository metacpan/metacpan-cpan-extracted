
use strict;
use warnings;

use Module::Build 0.2808;


my %module_build_args = (
  "build_requires" => {
    "Config" => 0,
    "English" => 0,
    "File::Find" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "Module::Build" => "0.2808",
    "Pod::Coverage::TrustPod" => 0,
    "Test::More" => 0,
    "Text::ParseWords" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.2808"
  },
  "dist_abstract" => "asynchronous ssh command invocation ",
  "dist_author" => [
    "Nick Stokoe <wulee\@cpan.org>"
  ],
  "dist_name" => "Net-SSH-Mechanize",
  "dist_version" => "0.1.3",
  "license" => "perl",
  "module_name" => "Net::SSH::Mechanize",
  "recommends" => {
    "Term::ReadKey" => 0,
    "Test::Pod" => "1.14",
    "Test::Pod::Coverage" => "1.04"
  },
  "recursive_test_files" => 1,
  "requires" => {
    "AnyEvent" => 0,
    "AnyEvent::Subprocess" => 0,
    "AnyEvent::Subprocess::Running" => 0,
    "Carp" => 0,
    "Coro" => 0,
    "Moose" => 0,
    "MooseX::Params::Validate" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
