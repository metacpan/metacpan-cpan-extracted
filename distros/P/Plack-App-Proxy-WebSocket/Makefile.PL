# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.011.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "proxy HTTP and WebSocket connections",
  "AUTHOR" => "Charles McGarvey <chazmcgarvey\@brokenzipper.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Plack-App-Proxy-WebSocket",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Plack::App::Proxy::WebSocket",
  "PREREQ_PM" => {
    "AnyEvent::Handle" => 0,
    "AnyEvent::Socket" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Parser::XS" => 0,
    "HTTP::Request" => 0,
    "Plack::App::Proxy" => 0,
    "Plack::Request" => 0,
    "URI" => 0,
    "namespace::clean" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent::Handle" => 0,
  "AnyEvent::Socket" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HTTP::Headers" => 0,
  "HTTP::Parser::XS" => 0,
  "HTTP::Request" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Plack::App::Proxy" => 0,
  "Plack::Request" => 0,
  "Test::More" => 0,
  "URI" => 0,
  "namespace::clean" => 0,
  "parent" => 0,
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
