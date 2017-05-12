use strict;
use warnings;

use Devel::CheckLib;
check_lib_or_exit(
    header => 'nanomsg/nn.h',
    lib => 'nanomsg',
);

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Low-level interface to the nanomsg scalability protocols library",
  "AUTHOR" => "Florian Ragwitz <rafl\@debian.org>, Boris Zentner <bzm\@2bz.de>",
  VERSION_FROM  => 'lib/NanoMsg/Raw.pm',

  "CONFIGURE_REQUIRES" => {
    "Devel::CheckLib" => "0.9",
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "NanoMsg-Raw",
  "EXE_FILES" => [],
  "LIBS" => "-lnanomsg",
  "LICENSE" => "mit",
  "NAME" => "NanoMsg::Raw",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "XSLoader" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => "0.89",
    "Test::SharedFork" => 0,
    "Test::TCP" => 0,
    "Time::HiRes" => 0
  },
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Devel::CheckLib" => "0.9",
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.89",
  "Test::SharedFork" => 0,
  "Test::TCP" => 0,
  "Time::HiRes" => 0,
  "XSLoader" => 0,
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
