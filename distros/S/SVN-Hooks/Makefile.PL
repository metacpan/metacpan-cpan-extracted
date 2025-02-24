# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Framework for implementing Subversion hooks",
  "AUTHOR" => "Gustavo L. de M. Chaves <gnustavo\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "SVN-Hooks",
  "LICENSE" => "perl",
  "NAME" => "SVN::Hooks",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Util" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "JIRA::REST" => 0,
    "SVN::Look" => 0,
    "SVN::Notify" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Config" => 0,
    "File::Compare" => 0,
    "File::Copy" => 0,
    "Test::More" => 0,
    "URI::file" => 0,
    "lib" => 0
  },
  "VERSION" => "1.36",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Config" => 0,
  "Cwd" => 0,
  "Data::Util" => 0,
  "Exporter" => 0,
  "File::Basename" => 0,
  "File::Compare" => 0,
  "File::Copy" => 0,
  "File::Path" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "JIRA::REST" => 0,
  "SVN::Look" => 0,
  "SVN::Notify" => 0,
  "Test::More" => 0,
  "URI::file" => 0,
  "lib" => 0,
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
