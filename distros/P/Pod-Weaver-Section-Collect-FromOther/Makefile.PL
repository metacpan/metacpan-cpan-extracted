
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Import sections from other POD",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Pod::Weaver" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Weaver-Section-Collect-FromOther",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Pod::Weaver::Section::Collect::FromOther",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "PPI" => 0,
    "Path::Class" => 0,
    "Pod::Elemental" => 0,
    "Pod::Elemental::Document" => 0,
    "Pod::Elemental::Element::Pod5::Command" => 0,
    "Pod::Elemental::Selectors" => 0,
    "Pod::Elemental::Transformer::Gatherer" => 0,
    "Pod::Elemental::Transformer::List::Converter" => 0,
    "Pod::Weaver::Plugin::EnsurePod5" => 0,
    "Pod::Weaver::Role::Preparer" => 0,
    "Pod::Weaver::Section::Collect" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



