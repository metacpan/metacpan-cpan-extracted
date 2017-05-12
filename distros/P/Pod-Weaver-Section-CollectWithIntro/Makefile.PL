
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Preface pod collections",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Moose::Autobox" => "0.10",
    "PPI" => 0,
    "Pod::Elemental" => 0,
    "Pod::Elemental::Selectors" => 0,
    "Pod::Elemental::Transformer::Nester" => 0,
    "Pod::Elemental::Transformer::Pod5" => 0,
    "Pod::Weaver" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Weaver-Section-CollectWithIntro",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Pod::Weaver::Section::CollectWithIntro",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Pod::Elemental::Element::Pod5::Ordinary" => 0,
    "Pod::Weaver::Section::Collect" => 0,
    "aliased" => 0,
    "autobox::Core" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.001",
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



