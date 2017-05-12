
use strict;
use warnings;

use 5.016000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Send data to a Graylog server for analysis",
  "AUTHOR" => "Kevin Mulholland <moodfarm\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-Graylog-Client",
  "EXE_FILES" => [
    "bin/graylog"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::Graylog::Client",
  "PREREQ_PM" => {
    "App::Basis" => 0,
    "App::Basis::Config" => 0,
    "Data::Printer" => 0,
    "Data::UUID" => 0,
    "Furl" => 0,
    "JSON" => 0,
    "JSON::Tiny" => 0,
    "Moo" => 0,
    "POSIX" => 0,
    "Sys::Hostname" => 0,
    "URI::Escape::XS" => 0,
    "constant" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.3",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Basis" => 0,
  "App::Basis::Config" => 0,
  "Data::Printer" => 0,
  "Data::UUID" => 0,
  "Furl" => 0,
  "JSON" => 0,
  "JSON::Tiny" => 0,
  "Moo" => 0,
  "POSIX" => 0,
  "Sys::Hostname" => 0,
  "Test::More" => 0,
  "URI::Escape::XS" => 0,
  "constant" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "vars" => 0,
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



