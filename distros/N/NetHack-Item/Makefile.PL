
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "parse and interact with a NetHack item",
  "AUTHOR" => "Shawn M Moore <sartak\@bestpractical.com>, Jesse Luehrs <doy at tozt dot net>, Sean Kelly <cpan\@katron.org>, Stefan O'Rear <stefanor\@cox.net>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "NetHack-Item",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "NetHack::Item",
  "PREREQ_PM" => {
    "Module::Pluggable" => "3.8",
    "Moose" => "0.90",
    "MooseX::Role::Parameterized" => "0.05",
    "NetHack::Monster::Spoiler" => "0.02",
    "Set::Object" => "1.00",
    "Test::Fatal" => "0.007",
    "Test::More" => "0.88"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.21",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Module::Pluggable" => "3.8",
  "Moose" => "0.90",
  "MooseX::Role::Parameterized" => "0.05",
  "NetHack::Monster::Spoiler" => "0.02",
  "Set::Object" => "1.00",
  "Test::Fatal" => "0.007",
  "Test::More" => "0.88"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



