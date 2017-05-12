
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "allow a module's pod to contain Pod::Coverage hints",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Coverage-TrustPod",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Pod::Coverage::TrustPod",
  "PREREQ_PM" => {
    "Pod::Coverage::CountParents" => 0,
    "Pod::Eventual::Simple" => 0,
    "Pod::Find" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.96",
    "lib" => 0
  },
  "VERSION" => "0.100003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Pod::Coverage::CountParents" => 0,
  "Pod::Eventual::Simple" => 0,
  "Pod::Find" => 0,
  "Test::More" => "0.96",
  "base" => 0,
  "lib" => 0,
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



