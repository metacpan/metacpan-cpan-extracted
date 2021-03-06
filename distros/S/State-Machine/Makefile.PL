
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.015.
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple State Machine Implementation",
  "AUTHOR" => "Al Newkirk <anewkirk\@ana.io>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "State-Machine",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "State::Machine",
  "PREREQ_PM" => {
    "Bubblegum" => "0.31",
    "Exporter::Tiny" => "0.038",
    "Function::Parameters" => "1.0401",
    "Throwable" => "0.200011"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/state/*.t t/state/machine/*.t"
  }
);


my %FallbackPrereqs = (
  "Bubblegum" => "0.31",
  "Exporter::Tiny" => "0.038",
  "Function::Parameters" => "1.0401",
  "Throwable" => "0.200011"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



