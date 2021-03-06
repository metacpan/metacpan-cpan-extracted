# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.039.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "POD viewer for QBit application",
  "AUTHOR" => "Sergei Svistunov <sergei-svistunov\@yandex.ru>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "QBit-WebInterface-Controller-Pod",
  "LICENSE" => "gpl",
  "NAME" => "QBit::WebInterface::Controller::Pod",
  "PREREQ_PM" => {
    "Pod::Checker" => 0,
    "Pod::Simple::HTML" => 0,
    "QBit::Application::Model" => 0,
    "QBit::WebInterface::Controller" => 0,
    "base" => 0,
    "qbit" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Pod::Checker" => 0,
  "Pod::Simple::HTML" => 0,
  "QBit::Application::Model" => 0,
  "QBit::WebInterface::Controller" => 0,
  "base" => 0,
  "qbit" => 0,
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
