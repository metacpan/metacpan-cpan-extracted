
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "flexible and extensible dispatch",
  "AUTHOR" => "Shawn M Moore, C<< <sartak at bestpractical.com> >>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Path-Dispatcher",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Path::Dispatcher",
  "PREREQ_PM" => {
    "Any::Moose" => "0.12",
    "Try::Tiny" => "0.02",
    "constant" => 0,
    "overload" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.06",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Any::Moose" => "0.12",
  "Test::Fatal" => 0,
  "Test::More" => "0.88",
  "Try::Tiny" => "0.02",
  "constant" => 0,
  "overload" => 0,
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



