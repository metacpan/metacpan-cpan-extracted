
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Bullet-proof rsync wrapper",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Sys-Bprsync",
  "EXE_FILES" => [
    "bin/bprsync.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Sys::Bprsync",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::Yak" => 0,
    "Config::Yak::RequiredConfig" => 0,
    "English" => 0,
    "File::Blarf" => 0,
    "Job::Manager" => 0,
    "Job::Manager::Job" => 0,
    "Job::Manager::Worker" => 0,
    "Linux::Pidfile" => 0,
    "Log::Tree" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Sys::CmdMod" => 0,
    "Sys::Run" => 0,
    "Try::Tiny" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.25",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Config::Yak" => 0,
  "Config::Yak::RequiredConfig" => 0,
  "English" => 0,
  "File::Blarf" => 0,
  "Job::Manager" => 0,
  "Job::Manager::Job" => 0,
  "Job::Manager::Worker" => 0,
  "Linux::Pidfile" => 0,
  "Log::Tree" => 0,
  "Log::Tree::RequiredLogger" => 0,
  "Moose" => 0,
  "MooseX::App::Cmd" => 0,
  "MooseX::App::Cmd::Command" => 0,
  "Sys::CmdMod" => 0,
  "Sys::Run" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "feature" => 0,
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



