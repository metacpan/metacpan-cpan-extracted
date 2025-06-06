# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.031.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A Cxn implementation which uses libcurl via Net::Curl",
  "AUTHOR" => "Enrico Zimuel <enrico.zimuel\@elastic.co>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Search-Elasticsearch-Cxn-NetCurl",
  "LICENSE" => "apache",
  "NAME" => "Search::Elasticsearch::Cxn::NetCurl",
  "PREREQ_PM" => {
    "HTTP::Parser::XS" => 0,
    "Moo" => 0,
    "Net::Curl::Easy" => 0,
    "Search::Elasticsearch" => "8.12",
    "Try::Tiny" => 0,
    "namespace::clean" => 0
  },
  "TEST_REQUIRES" => {
    "Cpanel::JSON::XS" => 0,
    "Data::Dumper" => 0,
    "File::Temp" => 0,
    "JSON::PP" => 0,
    "JSON::XS" => 0,
    "Log::Any::Adapter" => 0,
    "Log::Any::Adapter::Callback" => "0.09",
    "MIME::Base64" => 0,
    "POSIX" => 0,
    "Sub::Exporter" => 0,
    "Test::Deep" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.98",
    "Test::SharedFork" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "8.12",
  "test" => {
    "TESTS" => "t/*.t t/10_Basic/*.t t/20_Serializer/*.t t/30_Logger/*.t t/40_Transport/*.t t/50_Cxn_Pool/*.t t/60_Cxn/*.t t/95_TestServer/*.t t/Client_7_0/*.t t/Client_8_0/*.t"
  }
);


my %FallbackPrereqs = (
  "Cpanel::JSON::XS" => 0,
  "Data::Dumper" => 0,
  "File::Temp" => 0,
  "HTTP::Parser::XS" => 0,
  "JSON::PP" => 0,
  "JSON::XS" => 0,
  "Log::Any::Adapter" => 0,
  "Log::Any::Adapter::Callback" => "0.09",
  "MIME::Base64" => 0,
  "Moo" => 0,
  "Net::Curl::Easy" => 0,
  "POSIX" => 0,
  "Search::Elasticsearch" => "8.12",
  "Sub::Exporter" => 0,
  "Test::Deep" => 0,
  "Test::Exception" => 0,
  "Test::More" => "0.98",
  "Test::SharedFork" => 0,
  "Try::Tiny" => 0,
  "lib" => 0,
  "namespace::clean" => 0,
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
