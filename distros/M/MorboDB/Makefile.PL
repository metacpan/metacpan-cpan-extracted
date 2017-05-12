
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "In-memory database, mostly-compatible clone of MongoDB",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MorboDB",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MorboDB",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Clone" => 0,
    "Data::UUID" => 0,
    "MQUL" => "0.003",
    "Moo" => 0,
    "Scalar::Util" => 0,
    "Tie::IxHash" => 0,
    "boolean" => 0
  },
  "TEST_REQUIRES" => {
    "Test::FailWarnings" => 0,
    "Test::More" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Clone" => 0,
  "Data::UUID" => 0,
  "MQUL" => "0.003",
  "Moo" => 0,
  "Scalar::Util" => 0,
  "Test::FailWarnings" => 0,
  "Test::More" => 0,
  "Tie::IxHash" => 0,
  "Try::Tiny" => 0,
  "boolean" => 0,
  "strict" => 0,
  "utf8" => 0,
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



