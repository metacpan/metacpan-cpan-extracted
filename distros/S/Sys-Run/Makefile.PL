
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Run commands and handle their output.",
  "AUTHOR" => "Dominik Schulz <tex\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Sys-Run",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Sys::Run",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Blarf" => 0,
    "File::Temp" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Moose" => 0,
    "Net::Domain" => 0,
    "Time::HiRes" => 0,
    "feature" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "Test::MockObject::Universal" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Blarf" => 0,
  "File::Temp" => 0,
  "Log::Tree::RequiredLogger" => 0,
  "Moose" => 0,
  "Net::Domain" => 0,
  "Test::MockObject::Universal" => 0,
  "Test::More" => 0,
  "Time::HiRes" => 0,
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



