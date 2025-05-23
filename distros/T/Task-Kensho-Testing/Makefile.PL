# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.020.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A Glimpse at an Enlightened Perl: Testing",
  "AUTHOR" => "Chris Prather <chris\@prather.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Task-Kensho-Testing",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Task::Kensho::Testing",
  "PREREQ_PM" => {
    "Devel::Cover" => 0,
    "Test2::Suite" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::Memory::Cycle" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "Test::Requires" => 0,
    "Test::Simple" => 0,
    "Test::Warnings" => 0,
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
  "Devel::Cover" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Test2::Suite" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::Memory::Cycle" => 0,
  "Test::More" => 0,
  "Test::Pod" => 0,
  "Test::Pod::Coverage" => 0,
  "Test::Requires" => 0,
  "Test::Simple" => 0,
  "Test::Warnings" => 0,
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
