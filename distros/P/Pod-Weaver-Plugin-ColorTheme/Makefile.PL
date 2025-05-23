# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.023.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Plugin to use when building distribution which has ColorTheme::* modules",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Pod-Weaver-Plugin-ColorTheme",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Pod::Weaver::Plugin::ColorTheme",
  "PREREQ_PM" => {
    "Markdown::To::POD" => 0,
    "Module::List" => 0,
    "Moose" => 0,
    "Pod::Weaver::Role::AddTextToSection" => "0.06",
    "Pod::Weaver::Role::Section" => 0,
    "String::PodQuote" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Markdown::To::POD" => 0,
  "Module::List" => 0,
  "Moose" => 0,
  "Pod::Weaver::Role::AddTextToSection" => "0.06",
  "Pod::Weaver::Role::Section" => 0,
  "String::PodQuote" => 0,
  "Test::More" => 0,
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
