
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.030.
use strict;
use warnings;

use 5.008008;

use ExtUtils::MakeMaker;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SMS::Send driver for the WebSMS service",
  "AUTHOR" => "Alexander Hartmaier <abraxxa\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "SMS-Send-WebSMS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008008",
  "NAME" => "SMS::Send::WebSMS",
  "PREREQ_PM" => {
    "HTTP::Tiny" => "0.053",
    "IO::Socket::SSL" => "2.008",
    "JSON::MaybeXS" => "1.003003",
    "Mozilla::CA" => 20130114,
    "Net::SSLeay" => "1.66",
    "SMS::Send::Driver" => "0.06",
    "URI::Escape" => "1.65"
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => "0.32",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "HTTP::Tiny" => "0.053",
  "IO::Socket::SSL" => "2.008",
  "JSON::MaybeXS" => "1.003003",
  "Mozilla::CA" => 20130114,
  "Net::SSLeay" => "1.66",
  "SMS::Send::Driver" => "0.06",
  "Test::Exception" => "0.32",
  "Test::More" => "0.98",
  "URI::Escape" => "1.65"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



