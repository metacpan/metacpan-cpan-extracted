
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "an rsync-based backup script",
  "AUTHOR" => "Dominik Schulz <dominik.schulz\@gauner.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Sys-RevoBackup",
  "EXE_FILES" => [
    "bin/revobackup.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Sys::RevoBackup",
  "PREREQ_PM" => {
    "Config::Yak" => 0,
    "Config::Yak::OrderedPlugins" => 0,
    "Config::Yak::RequiredConfig" => 0,
    "English" => 0,
    "File::Blarf" => 0,
    "Job::Manager" => 0,
    "Linux::Pidfile" => 0,
    "List::MoreUtils" => 0,
    "Log::Tree" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Sys::Bprsync" => "0.17",
    "Sys::Bprsync::Job" => 0,
    "Sys::Bprsync::Worker" => 0,
    "Sys::FS" => 0,
    "Sys::Hostname::FQDN" => 0,
    "Sys::RotateBackup" => 0,
    "Sys::Run" => 0,
    "Try::Tiny" => 0,
    "Zabbix::Sender" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "Test::MockObject::Universal" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.27",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config::Yak" => 0,
  "Config::Yak::OrderedPlugins" => 0,
  "Config::Yak::RequiredConfig" => 0,
  "English" => 0,
  "File::Blarf" => 0,
  "File::Temp" => 0,
  "Job::Manager" => 0,
  "Linux::Pidfile" => 0,
  "List::MoreUtils" => 0,
  "Log::Tree" => 0,
  "Log::Tree::RequiredLogger" => 0,
  "Moose" => 0,
  "MooseX::App::Cmd" => 0,
  "MooseX::App::Cmd::Command" => 0,
  "Sys::Bprsync" => "0.17",
  "Sys::Bprsync::Job" => 0,
  "Sys::Bprsync::Worker" => 0,
  "Sys::FS" => 0,
  "Sys::Hostname::FQDN" => 0,
  "Sys::RotateBackup" => 0,
  "Sys::Run" => 0,
  "Test::MockObject::Universal" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "Zabbix::Sender" => 0,
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



