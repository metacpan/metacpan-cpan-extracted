# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.008005;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "verify SMTP recipient addresses",
  "AUTHOR" => "Markus Benning <ich\@markusbenning.de>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Net-SMTP-Verify",
  "EXE_FILES" => [
    "bin/smtp-verify"
  ],
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.008005",
  "NAME" => "Net::SMTP::Verify",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Digest::SHA" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "MooseX::Getopt" => 0,
    "Net::Cmd" => 0,
    "Net::DNS::Resolver" => 0,
    "Net::SMTP" => "3.07",
    "Sys::Hostname" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::Mock::Net::Server::Mail" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "Digest::SHA" => 0,
  "JSON" => 0,
  "Moose" => 0,
  "MooseX::Getopt" => 0,
  "Net::Cmd" => 0,
  "Net::DNS::Resolver" => 0,
  "Net::SMTP" => "3.07",
  "Sys::Hostname" => 0,
  "Test::Exception" => 0,
  "Test::Mock::Net::Server::Mail" => 0,
  "Test::More" => 0,
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
