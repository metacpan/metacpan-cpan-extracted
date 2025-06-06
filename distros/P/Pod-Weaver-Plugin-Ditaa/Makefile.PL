# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.037.
use strict;
use warnings;

use 5.018;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "include ditaa diagrams in your pod",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Pod-Weaver-Plugin-Ditaa",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.018",
  "NAME" => "Pod::Weaver::Plugin::Ditaa",
  "PREREQ_PM" => {
    "Capture::Tiny" => 0,
    "IO::All" => 0,
    "IPC::System::Simple" => 0,
    "MIME::Base64" => 0,
    "Moose" => 0,
    "Pod::Elemental::Transformer" => 0,
    "Pod::Weaver::Role::Dialect" => 0,
    "namespace::clean" => 0
  },
  "TEST_REQUIRES" => {
    "Pod::Elemental" => 0,
    "Pod::Elemental::Transformer::Pod5" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.001006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "ExtUtils::MakeMaker" => 0,
  "IO::All" => 0,
  "IPC::System::Simple" => 0,
  "MIME::Base64" => 0,
  "Moose" => 0,
  "Pod::Elemental" => 0,
  "Pod::Elemental::Transformer" => 0,
  "Pod::Elemental::Transformer::Pod5" => 0,
  "Pod::Weaver::Role::Dialect" => 0,
  "Test::Differences" => 0,
  "Test::More" => "0.88",
  "namespace::clean" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
