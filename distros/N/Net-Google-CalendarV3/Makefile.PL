# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.036.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Access Google Calendars using the v3 API",
  "AUTHOR" => "Rhesa Rozendaal <rhesa\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Net-Google-CalendarV3",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::Google::CalendarV3",
  "PREREQ_PM" => {
    "DateTime::Format::ISO8601" => 0,
    "JSON::XS" => 0,
    "Kavorka" => 0,
    "Moose" => 0,
    "Try::Tiny" => 0,
    "Types::Standard" => 0,
    "WWW::JSON" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DateTime::Format::ISO8601" => 0,
  "ExtUtils::MakeMaker" => 0,
  "JSON::XS" => 0,
  "Kavorka" => 0,
  "Moose" => 0,
  "Try::Tiny" => 0,
  "Types::Standard" => 0,
  "WWW::JSON" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
