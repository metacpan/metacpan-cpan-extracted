# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.017.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "manages books written in the Pod::PseudoPod format",
  "AUTHOR" => "chromatic <chromatic\@wgz.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Pod-PseudoPod-Book",
  "EXE_FILES" => [
    "bin/ppbook"
  ],
  "LICENSE" => "perl",
  "NAME" => "Pod::PseudoPod::Book",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "Config::Tiny" => 0,
    "EBook::EPUB" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::chdir" => 0,
    "HTML::Entities" => 0,
    "Path::Class" => 0,
    "Pod::PseudoPod::DOM::App::ToHTML" => 0,
    "Pod::PseudoPod::DOM::App::ToLaTeX" => 0,
    "Pod::PseudoPod::DOM::App::ToPML" => 0,
    "Pod::PseudoPod::HTML" => 0,
    "autodie" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Modern::Perl" => 0,
    "Module::Pluggable" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "1.20210620.2051",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd::Setup" => 0,
  "Config::Tiny" => 0,
  "EBook::EPUB" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Path" => 0,
  "File::Slurp" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::chdir" => 0,
  "HTML::Entities" => 0,
  "Modern::Perl" => 0,
  "Module::Pluggable" => 0,
  "Path::Class" => 0,
  "Pod::PseudoPod::DOM::App::ToHTML" => 0,
  "Pod::PseudoPod::DOM::App::ToLaTeX" => 0,
  "Pod::PseudoPod::DOM::App::ToPML" => 0,
  "Pod::PseudoPod::HTML" => 0,
  "Test::More" => 0,
  "autodie" => 0,
  "lib" => 0,
  "parent" => 0,
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
