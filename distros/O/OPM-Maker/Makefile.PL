# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Module/App to build and test OPM packages for Znuny, OTOBO, ((OTRS)) Community edition.",
  "AUTHOR" => "Renee Baecker <reneeb\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "OPM-Maker",
  "EXE_FILES" => [
    "bin/opmbuild"
  ],
  "LICENSE" => "artistic_2",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "OPM::Maker",
  "PREREQ_PM" => {
    "App::Cmd" => 0,
    "Carp" => 0,
    "File::Basename" => 0,
    "File::Find::Rule" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => 0,
    "MIME::Base64" => 0,
    "OPM::Validate" => "1.10",
    "Path::Class" => 0,
    "Sys::Hostname" => 0,
    "Text::Gitignore" => "0.04",
    "XML::LibXML" => 0,
    "XML::LibXML::PrettyPrint" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Copy" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "Test::LongString" => 0,
    "Test::More" => 0
  },
  "VERSION" => "1.17",
  "test" => {
    "TESTS" => "t/*.t t/build/*.t t/build_find_sopm/*.t t/dbtest/*.t t/dependencies/*.t t/dependencies_find_sopm/*.t t/filetest/*.t t/filetest_find_sopm/*.t t/filetest_ignore/*.t t/index/*.t t/sopmtest/*.t t/sopmtest_find_sopm/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd" => 0,
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Find::Rule" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "Getopt::Long" => 0,
  "HTTP::Tiny" => 0,
  "MIME::Base64" => 0,
  "OPM::Validate" => "1.10",
  "Path::Class" => 0,
  "Sys::Hostname" => 0,
  "Test::LongString" => 0,
  "Test::More" => 0,
  "Text::Gitignore" => "0.04",
  "XML::LibXML" => 0,
  "XML::LibXML::PrettyPrint" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
