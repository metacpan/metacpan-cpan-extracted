
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plack Middleware to integrate with Mozilla Persona (Auth by email)",
  "AUTHOR" => "Jo\x{e3}o Bolila <bolila\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Plack-Middleware-Auth-BrowserID",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::Middleware::Auth::BrowserID",
  "PREREQ_PM" => {
    "HTTP::Request::Common" => "6.04",
    "JSON" => "2.90",
    "LWP::Protocol::https" => "6.04",
    "LWP::UserAgent" => "6.05",
    "Mozilla::CA" => 20130114,
    "Net::Ping" => "2.36",
    "Plack::Middleware::Session" => "0.21",
    "Plack::Response" => "1.0029",
    "Plack::Util::Accessor" => 0
  },
  "TEST_REQUIRES" => {
    "Plack::Test" => 0,
    "Test::Compile" => 0,
    "Test::More" => "0.98"
  },
  "VERSION" => "0.0.7",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "HTTP::Request::Common" => "6.04",
  "JSON" => "2.90",
  "LWP::Protocol::https" => "6.04",
  "LWP::UserAgent" => "6.05",
  "Mozilla::CA" => 20130114,
  "Net::Ping" => "2.36",
  "Plack::Middleware::Session" => "0.21",
  "Plack::Response" => "1.0029",
  "Plack::Test" => 0,
  "Plack::Util::Accessor" => 0,
  "Test::Compile" => 0,
  "Test::More" => "0.98"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



