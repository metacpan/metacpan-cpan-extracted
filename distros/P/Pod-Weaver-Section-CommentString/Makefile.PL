# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.007.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Add Pod::Weaver section with content extracted from comment with specified keyword",
  "AUTHOR" => "Milan Sorm <sorm\@is4u.cz>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.28"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "Module::Build" => "0.28"
  },
  "DISTNAME" => "Pod-Weaver-Section-CommentString",
  "LICENSE" => "perl",
  "NAME" => "Pod::Weaver::Section::CommentString",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Pod::Elemental::Element::Nested" => 0,
    "Pod::Elemental::Element::Pod5::Command" => 0,
    "Pod::Weaver::Role::Section" => 0,
    "Pod::Weaver::Role::StringFromComment" => 0,
    "aliased" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Module::Build" => "0.28",
  "Moose" => 0,
  "Pod::Elemental::Element::Nested" => 0,
  "Pod::Elemental::Element::Pod5::Command" => 0,
  "Pod::Weaver::Role::Section" => 0,
  "Pod::Weaver::Role::StringFromComment" => 0,
  "aliased" => 0,
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
