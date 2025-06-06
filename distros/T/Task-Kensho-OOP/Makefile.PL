# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.020.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A Glimpse at an Enlightened Perl: Object Oriented Programming",
  "AUTHOR" => "Chris Prather <chris\@prather.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Task-Kensho-OOP",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Task::Kensho::OOP",
  "PREREQ_PM" => {
    "Moo" => 0,
    "Moose" => 0,
    "MooseX::Aliases" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::Role::Parameterized" => 0,
    "MooseX::SimpleConfig" => 0,
    "MooseX::StrictConstructor" => 0,
    "Package::Variant" => 0,
    "Type::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.41",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Moo" => 0,
  "Moose" => 0,
  "MooseX::Aliases" => 0,
  "MooseX::Getopt" => 0,
  "MooseX::NonMoose" => 0,
  "MooseX::Role::Parameterized" => 0,
  "MooseX::SimpleConfig" => 0,
  "MooseX::StrictConstructor" => 0,
  "Package::Variant" => 0,
  "Test::More" => 0,
  "Type::Tiny" => 0,
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
