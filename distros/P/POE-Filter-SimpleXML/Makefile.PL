# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.017.
use strict;
use warnings;

use 5.024;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Simple XML parsing for POE",
  "AUTHOR" => "Mathieu Arnold <m\@absolight.fr>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "POE-Filter-SimpleXML",
  "LICENSE" => "bsd",
  "MIN_PERL_VERSION" => "5.024",
  "NAME" => "POE::Filter::SimpleXML",
  "PREREQ_PM" => {
    "Carp" => 0,
    "English" => 0,
    "Moose" => 0,
    "Moose::Object" => 0,
    "MooseX::NonMoose" => 0,
    "POE::Filter" => 0,
    "XML::LibXML" => 0,
    "strictures" => 2,
    "utf8" => 0
  },
  "TEST_REQUIRES" => {
    "App::Prove::Plugin::Count" => 0,
    "App::Prove::Watch" => 0,
    "Devel::Cover" => 0,
    "Dist::Zilla::App::Command::cover" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "lib::relative" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Prove::Plugin::Count" => 0,
  "App::Prove::Watch" => 0,
  "Carp" => 0,
  "Devel::Cover" => 0,
  "Dist::Zilla::App::Command::cover" => 0,
  "English" => 0,
  "Moose" => 0,
  "Moose::Object" => 0,
  "MooseX::NonMoose" => 0,
  "POE::Filter" => 0,
  "Test::Exception" => 0,
  "Test::MockObject" => 0,
  "Test::More" => 0,
  "XML::LibXML" => 0,
  "lib::relative" => 0,
  "strict" => 0,
  "strictures" => 2,
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
