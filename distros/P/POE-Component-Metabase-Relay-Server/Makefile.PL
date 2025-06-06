# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A Metabase relay server component",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.42",
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.42"
  },
  "DISTNAME" => "POE-Component-Metabase-Relay-Server",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006000",
  "NAME" => "POE::Component::Metabase::Relay::Server",
  "PREREQ_PM" => {
    "CPAN::Testers::Report" => "1.999",
    "DBD::SQLite" => "1.29",
    "DBI" => "1.609",
    "Data::UUID" => "1.203",
    "JSON::MaybeXS" => "1.004008",
    "Metabase::Fact" => "0.011",
    "Metabase::User::Profile" => "0.003",
    "Metabase::User::Secret" => "0.003",
    "Module::Load::Conditional" => 0,
    "Moose" => "1.01",
    "Moose::Util::TypeConstraints" => "1.01",
    "MooseX::POE" => "0.205",
    "MooseX::Types::Path::Class" => "0.05",
    "MooseX::Types::URI" => "0.03",
    "POE" => "1.299",
    "POE::Component::Client::HTTP" => "0.948",
    "POE::Component::Client::Keepalive" => "0.271",
    "POE::Component::EasyDBI" => "1.23",
    "POE::Component::Metabase::Client::Submit" => "0.12",
    "POE::Component::Resolver" => "0.921",
    "Params::Util" => "1.01",
    "Storable" => 0,
    "Test::POE::Server::TCP" => "1.12",
    "Time::HiRes" => 0,
    "URI" => "1.52",
    "base" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.47"
  },
  "VERSION" => "0.40",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CPAN::Testers::Report" => "1.999",
  "DBD::SQLite" => "1.29",
  "DBI" => "1.609",
  "Data::UUID" => "1.203",
  "ExtUtils::MakeMaker" => "6.42",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON::MaybeXS" => "1.004008",
  "Metabase::Fact" => "0.011",
  "Metabase::User::Profile" => "0.003",
  "Metabase::User::Secret" => "0.003",
  "Module::Load::Conditional" => 0,
  "Moose" => "1.01",
  "Moose::Util::TypeConstraints" => "1.01",
  "MooseX::POE" => "0.205",
  "MooseX::Types::Path::Class" => "0.05",
  "MooseX::Types::URI" => "0.03",
  "POE" => "1.299",
  "POE::Component::Client::HTTP" => "0.948",
  "POE::Component::Client::Keepalive" => "0.271",
  "POE::Component::EasyDBI" => "1.23",
  "POE::Component::Metabase::Client::Submit" => "0.12",
  "POE::Component::Resolver" => "0.921",
  "Params::Util" => "1.01",
  "Storable" => 0,
  "Test::More" => "0.47",
  "Test::POE::Server::TCP" => "1.12",
  "Time::HiRes" => 0,
  "URI" => "1.52",
  "base" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
