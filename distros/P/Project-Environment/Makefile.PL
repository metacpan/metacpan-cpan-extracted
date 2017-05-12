
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Set and detect project environment via .environment file.",
  "AUTHOR" => "Roman F. <romanf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Project-Environment",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Project::Environment",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Inspector" => 0,
    "File::Spec" => 0,
    "Module::Path" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Role::Flyweight" => 0,
    "MooseX::Types::Path::Tiny" => 0,
    "Path::FindDev" => 0,
    "Path::Tiny" => 0,
    "overload" => 0,
    "version" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Most" => 0,
    "lib::abs" => 0
  },
  "VERSION" => "v1.2.0",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Inspector" => 0,
  "File::Spec" => 0,
  "Module::Path" => 0,
  "Moose" => 0,
  "Moose::Role" => 0,
  "MooseX::Role::Flyweight" => 0,
  "MooseX::Types::Path::Tiny" => 0,
  "Path::FindDev" => 0,
  "Path::Tiny" => 0,
  "Test::Most" => 0,
  "lib::abs" => 0,
  "overload" => 0,
  "version" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



