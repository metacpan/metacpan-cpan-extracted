# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.031.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Async API for Elasticsearch using Promises",
  "AUTHOR" => "Enrico Zimuel <enrico.zimuel\@elastic.co>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Search-Elasticsearch-Async",
  "LICENSE" => "apache",
  "NAME" => "Search::Elasticsearch::Async",
  "PREREQ_PM" => {
    "AnyEvent::HTTP" => 0,
    "AnyEvent::TLS" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Promises" => "0.93",
    "Scalar::Util" => 0,
    "Search::Elasticsearch" => "8.00",
    "Sub::Exporter" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "namespace::clean" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "AE" => 0,
    "Cpanel::JSON::XS" => 0,
    "Data::Dumper" => 0,
    "EV" => 0,
    "File::Temp" => 0,
    "JSON::PP" => 0,
    "JSON::XS" => 0,
    "Log::Any::Adapter" => 0,
    "Log::Any::Adapter::Callback" => "0.09",
    "POSIX" => 0,
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.98",
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "8.12",
  "test" => {
    "TESTS" => "t/*.t t/10_Basic_Async/*.t t/20_Serializer_Async/*.t t/30_Logger_Async/*.t t/40_Transport_Async/*.t t/50_Cxn_Pool_Async/*.t t/60_Cxn_Async/*.t t/Client_7_0_Async/*.t t/Client_8_0_Async/*.t"
  }
);


my %FallbackPrereqs = (
  "AE" => 0,
  "AnyEvent::HTTP" => 0,
  "AnyEvent::TLS" => 0,
  "Cpanel::JSON::XS" => 0,
  "Data::Dumper" => 0,
  "EV" => 0,
  "File::Temp" => 0,
  "JSON::PP" => 0,
  "JSON::XS" => 0,
  "Log::Any::Adapter" => 0,
  "Log::Any::Adapter::Callback" => "0.09",
  "Moo" => 0,
  "Moo::Role" => 0,
  "POSIX" => 0,
  "Promises" => "0.93",
  "Scalar::Util" => 0,
  "Search::Elasticsearch" => "8.00",
  "Sub::Exporter" => 0,
  "Test::Deep" => 0,
  "Test::Exception" => 0,
  "Test::More" => "0.98",
  "Time::HiRes" => 0,
  "Try::Tiny" => 0,
  "lib" => 0,
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
