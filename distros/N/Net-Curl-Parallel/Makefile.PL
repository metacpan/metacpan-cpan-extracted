# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "perform concurrent HTTP requests using libcurl",
  "AUTHOR" => "ZipRecruiter",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Net-Curl-Parallel",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014000",
  "NAME" => "Net::Curl::Parallel",
  "PREREQ_PM" => {
    "Data::Printer" => 0,
    "File::Find::Rule" => 0,
    "Guard" => 0,
    "HTTP::Parser::XS" => 0,
    "HTTP::Response" => 0,
    "Moo" => 0,
    "Net::Curl::Easy" => 0,
    "Net::Curl::Multi" => 0,
    "Path::Tiny" => 0,
    "Type::Library" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0,
    "URI::Fast" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Perl::Critic" => 0,
    "Scalar::Util" => 0,
    "Test2::API" => 0,
    "Test2::IPC" => 0,
    "Test2::Plugin::SpecDeclare" => 0,
    "Test2::Suite" => 0,
    "Test2::Todo" => 0,
    "Test2::Tools::Explain" => 0,
    "Test2::Tools::Spec" => 0,
    "Test2::V0" => 0,
    "Test::HTTP::MockServer" => 0,
    "Test::MockModule" => 0,
    "Test::MockTime" => 0,
    "Test::More" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod" => 0,
    "namespace::autoclean" => 0,
    "parent" => 0,
    "strictures" => 0
  },
  "VERSION" => "2.0.0",
  "test" => {
    "TESTS" => "t/*.t t/Net/Curl/*.t t/Net/Curl/Parallel/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Printer" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Find::Rule" => 0,
  "File::Spec" => 0,
  "Guard" => 0,
  "HTTP::Parser::XS" => 0,
  "HTTP::Response" => 0,
  "Moo" => 0,
  "Net::Curl::Easy" => 0,
  "Net::Curl::Multi" => 0,
  "Path::Tiny" => 0,
  "Perl::Critic" => 0,
  "Scalar::Util" => 0,
  "Test2::API" => 0,
  "Test2::IPC" => 0,
  "Test2::Plugin::SpecDeclare" => 0,
  "Test2::Suite" => 0,
  "Test2::Todo" => 0,
  "Test2::Tools::Explain" => 0,
  "Test2::Tools::Spec" => 0,
  "Test2::V0" => 0,
  "Test::HTTP::MockServer" => 0,
  "Test::MockModule" => 0,
  "Test::MockTime" => 0,
  "Test::More" => 0,
  "Test::Perl::Critic" => 0,
  "Test::Pod" => 0,
  "Type::Library" => 0,
  "Type::Utils" => 0,
  "Types::Standard" => 0,
  "URI::Fast" => 0,
  "namespace::autoclean" => 0,
  "parent" => 0,
  "strictures" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
