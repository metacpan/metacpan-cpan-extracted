# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 7.1101;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A perl interface to the Twitter API",
  "AUTHOR" => "Marc Mims <mmims\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "7.1101"
  },
  "DISTNAME" => "Net-Twitter",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "Net::Twitter",
  "PREREQ_PM" => {
    "Carp::Clan" => 0,
    "Class::Load" => 0,
    "Data::Visitor::Callback" => 0,
    "DateTime" => 0,
    "DateTime::Format::Strptime" => 0,
    "Devel::StackTrace" => 0,
    "Digest::SHA" => 0,
    "Encode" => 0,
    "HTML::Entities" => 0,
    "HTTP::Request::Common" => 0,
    "IO::Socket::SSL" => "2.005",
    "JSON::MaybeXS" => 0,
    "LWP::Protocol::https" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Exporter" => 0,
    "Moose::Meta::Method" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Role::Parameterized" => 0,
    "Net::HTTP" => ">= 0, != 6.04, != 6.05",
    "Net::Netrc" => 0,
    "Net::OAuth" => 0,
    "Scalar::Util" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "File::Spec" => 0,
    "HTTP::Response" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "LWP::UserAgent" => "5.819",
    "Net::OAuth::Message" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.98",
    "Test::Warn" => 0,
    "base" => 0,
    "blib" => "1.01",
    "lib" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.01043",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Carp::Clan" => 0,
  "Class::Load" => 0,
  "Data::Visitor::Callback" => 0,
  "DateTime" => 0,
  "DateTime::Format::Strptime" => 0,
  "Devel::StackTrace" => 0,
  "Digest::SHA" => 0,
  "Encode" => 0,
  "File::Spec" => 0,
  "HTML::Entities" => 0,
  "HTTP::Request::Common" => 0,
  "HTTP::Response" => 0,
  "IO::Handle" => 0,
  "IO::Socket::SSL" => "2.005",
  "IPC::Open3" => 0,
  "JSON::MaybeXS" => 0,
  "LWP::Protocol::https" => 0,
  "LWP::UserAgent" => "5.819",
  "List::Util" => 0,
  "Moose" => 0,
  "Moose::Exporter" => 0,
  "Moose::Meta::Method" => 0,
  "Moose::Role" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::Role::Parameterized" => 0,
  "Net::HTTP" => ">= 0, != 6.04, != 6.05",
  "Net::Netrc" => 0,
  "Net::OAuth" => 0,
  "Net::OAuth::Message" => 0,
  "Scalar::Util" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.98",
  "Test::Warn" => 0,
  "Time::HiRes" => 0,
  "Try::Tiny" => 0,
  "URI" => 0,
  "URI::Escape" => 0,
  "base" => 0,
  "blib" => "1.01",
  "lib" => 0,
  "namespace::autoclean" => 0,
  "overload" => 0,
  "strict" => 0,
  "utf8" => 0,
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
