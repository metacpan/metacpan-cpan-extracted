
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "identify NetHack items using shopkeepers",
  "AUTHOR" => "Shawn M Moore <code\@sartak.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "NetHack-PriceID",
  "EXE_FILES" => [
    "bin/priceid"
  ],
  "LICENSE" => "perl",
  "NAME" => "NetHack::PriceID",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Exporter" => 0,
    "Getopt::Euclid" => 0,
    "base" => 0,
    "integer" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Exporter" => 0,
  "File::Spec" => 0,
  "Getopt::Euclid" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test::More" => "0.88",
  "base" => 0,
  "integer" => 0,
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



