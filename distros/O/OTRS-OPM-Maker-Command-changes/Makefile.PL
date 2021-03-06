# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate changes file based on vcs commits",
  "AUTHOR" => "Renee Baecker <reneeb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "OTRS-OPM-Maker-Command-changes",
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "OTRS::OPM::Maker::Command::changes",
  "PREREQ_PM" => {
    "Capture::Tiny" => "0.24",
    "Carp" => 0,
    "File::Basename" => 0,
    "File::Find::Rule" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "JSON" => "2.27",
    "List::Util" => "1.33",
    "OTRS::OPM::Maker" => 0,
    "Path::Class" => 0,
    "Test::Exception" => "0.35",
    "Test::LongString" => "0.15"
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/base/*.t t/utils/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => "0.24",
  "Carp" => 0,
  "File::Basename" => 0,
  "File::Find::Rule" => 0,
  "File::Spec" => 0,
  "IO::File" => 0,
  "JSON" => "2.27",
  "List::Util" => "1.33",
  "OTRS::OPM::Maker" => 0,
  "Path::Class" => 0,
  "Test::Exception" => "0.35",
  "Test::LongString" => "0.15"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
