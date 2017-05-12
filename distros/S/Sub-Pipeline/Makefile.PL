
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "subs composed of sequential pieces",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Sub-Pipeline",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Sub::Pipeline",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exception::Class" => "1.22",
    "Params::Util" => "0.22",
    "Sub::Exporter" => "0.95",
    "Sub::Install" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Exporter" => 0,
    "Test::More" => "0.96",
    "base" => 0,
    "lib" => 0
  },
  "VERSION" => "0.011",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Exception::Class" => "1.22",
  "Exporter" => 0,
  "Params::Util" => "0.22",
  "Sub::Exporter" => "0.95",
  "Sub::Install" => 0,
  "Test::More" => "0.96",
  "base" => 0,
  "lib" => 0,
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



