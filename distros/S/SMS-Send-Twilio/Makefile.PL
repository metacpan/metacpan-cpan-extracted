use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  "ABSTRACT" => "SMS::Send backend for the Twilio API.",
  "AUTHOR" => "Michiel Beijen <michielb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
  },
  "MIN_PERL_VERSION" => "5.10.1",
  "DISTNAME" => "SMS-Send-Twilio",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SMS::Send::Twilio",
  "PREREQ_PM" => {
    "SMS::Send" => 1,
    "WWW::Twilio::API" => "0.15",
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
  },
  "VERSION_FROM" => "lib/SMS/Send/Twilio.pm",
  "test" => {
    "TESTS" => "t/*.t"
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/mbeijen/SMS-Send-Twilio',
      bugtracker => 'https://github.com/mbeijen/SMS-Send-Twilio/issues',
    },
  },
);
