
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - Fake modules for testing the automation layer",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Class::C3" => 0,
    "MRO::Compat" => 0,
    "Tapper::Schema::TestTools" => 0,
    "Test::Fixture::DBIC::Schema" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-Fake",
  "EXE_FILES" => [
    "bin/fake-testmachine"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::Fake",
  "PREREQ_PM" => {
    "Devel::Backtrace" => 0,
    "Moose" => 0,
    "POSIX" => 0,
    "Tapper::Base" => 0,
    "Tapper::Config" => 0,
    "Tapper::MCP::Scheduler::Controller" => 0,
    "Tapper::Model" => 0,
    "UNIVERSAL" => 0,
    "YAML::Syck" => 0,
    "autodie" => 0,
    "common::sense" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.1.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



