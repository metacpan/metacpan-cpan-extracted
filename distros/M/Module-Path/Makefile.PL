# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.032.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "get the full path to a locally installed module",
  "AUTHOR" => "Neil Bowers <neilb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Module-Path",
  "EXE_FILES" => [
    "bin/mpath"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Module::Path",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "Getopt::Long" => 0,
    "Pod::Usage" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Devel::FindPerl" => 0,
    "File::Spec::Functions" => 0,
    "FindBin" => "0.05",
    "Test::More" => "0.88"
  },
  "VERSION" => "0.19",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cwd" => 0,
  "Devel::FindPerl" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Spec::Functions" => 0,
  "FindBin" => "0.05",
  "Getopt::Long" => 0,
  "Pod::Usage" => 0,
  "Test::More" => "0.88",
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
