
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Monitoring dashboard",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Monitoring-Reporter",
  "EXE_FILES" => [
    "bin/mreporter.pl",
    "bin/mreporter-web.pl",
    "bin/mreporter-web.psgi"
  ],
  "LICENSE" => "perl",
  "NAME" => "Monitoring::Reporter",
  "PREREQ_PM" => {
    "Cache::MemoryCache" => 0,
    "Config::Yak" => 0,
    "Config::Yak::LazyConfig" => 0,
    "Config::Yak::RequiredConfig" => 0,
    "DBI" => 0,
    "Data::Dumper" => 0,
    "File::ShareDir" => 0,
    "IO::Socket::INET" => 0,
    "Log::Tree" => 0,
    "Log::Tree::Logger" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Module::Pluggable" => 0,
    "Monitoring::Livestatus" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Plack::Builder" => 0,
    "Plack::Loader" => 0,
    "Plack::Request" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "feature" => 0,
    "lib" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cache::MemoryCache" => 0,
  "Config::Yak" => 0,
  "Config::Yak::LazyConfig" => 0,
  "Config::Yak::RequiredConfig" => 0,
  "DBI" => 0,
  "Data::Dumper" => 0,
  "File::ShareDir" => 0,
  "IO::Socket::INET" => 0,
  "Log::Tree" => 0,
  "Log::Tree::Logger" => 0,
  "Log::Tree::RequiredLogger" => 0,
  "Module::Pluggable" => 0,
  "Monitoring::Livestatus" => 0,
  "Moose" => 0,
  "MooseX::App::Cmd" => 0,
  "MooseX::App::Cmd::Command" => 0,
  "Plack::Builder" => 0,
  "Plack::Loader" => 0,
  "Plack::Request" => 0,
  "Template" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "feature" => 0,
  "lib" => 0,
  "mro" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


