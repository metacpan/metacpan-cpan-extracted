# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "what modules shipped with versions of Znuny (>= 6.0.30)",
  "AUTHOR" => "Renee Baecker <reneeb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Module-Znuny-CoreList",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "Module::Znuny::CoreList",
  "PREREQ_PM" => {},
  "TEST_REQUIRES" => {
    "File::Copy" => 0,
    "File::Path" => 0,
    "FindBin" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Copy" => 0,
  "File::Path" => 0,
  "FindBin" => 0,
  "Pod::Coverage::TrustPod" => 0,
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
