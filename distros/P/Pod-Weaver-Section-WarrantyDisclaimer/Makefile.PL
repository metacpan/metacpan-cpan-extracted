
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Add a standard DISCLAIMER OF WARRANTY section (for your Perl module)",
  "AUTHOR" => "Ryan C. Thompson <rct\@thompsonclan.org>",
  "BUILD_REQUIRES" => {
    "Carp" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Weaver-Section-WarrantyDisclaimer",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Pod::Weaver::Section::WarrantyDisclaimer",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Pod::Elemental::Element::Nested" => 0,
    "Pod::Elemental::Element::Pod5::Ordinary" => 0,
    "Pod::Weaver::Role::Section" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.121290",
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



