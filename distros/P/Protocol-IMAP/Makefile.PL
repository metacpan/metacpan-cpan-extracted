
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Support for RFC3501 Internet Message Access Protocol (IMAP4)",
  "AUTHOR" => "Tom Molesworth <protocol-imap\@entitymodel.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Protocol-IMAP",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Protocol::IMAP",
  "PREREQ_PM" => {
    "Authen::SASL" => 0,
    "Encode::IMAPUTF7" => 0,
    "POSIX" => 0,
    "Socket" => 0,
    "Time::HiRes" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::CheckDeps" => "0.010",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Authen::SASL" => 0,
  "Encode::IMAPUTF7" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "POSIX" => 0,
  "Socket" => 0,
  "Test::CheckDeps" => "0.010",
  "Test::More" => "0.98",
  "Time::HiRes" => 0,
  "parent" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



