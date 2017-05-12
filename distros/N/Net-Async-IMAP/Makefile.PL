
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Asynchronous IMAP handling",
  "AUTHOR" => "Tom Molesworth <net-async-imap\@entitymodel.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Async-IMAP",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Async::IMAP",
  "PREREQ_PM" => {
    "IO::Async" => "0.54",
    "IO::Async::SSL" => "0.12",
    "Protocol::IMAP" => "0.004",
    "Socket" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.98"
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "IO::Async" => "0.54",
  "IO::Async::SSL" => "0.12",
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Protocol::IMAP" => "0.004",
  "Socket" => 0,
  "Test::More" => "0.98",
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



