# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.036.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Use Pye as a Plack logger",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Plack-Middleware-PyeLogger",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Plack::Middleware::PyeLogger",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Plack::Middleware" => 0,
    "Plack::Util::Accessor" => 0,
    "Pye" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "2.000001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Plack::Middleware" => 0,
  "Plack::Util::Accessor" => 0,
  "Pye" => 0,
  "Test::More" => 0,
  "parent" => 0,
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
