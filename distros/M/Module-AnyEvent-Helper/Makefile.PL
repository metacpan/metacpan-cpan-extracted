
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Helper module to make other modules AnyEvent-friendly",
  "AUTHOR" => "Yasutaka ATARASHI <yakex\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Module-AnyEvent-Helper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Module::AnyEvent::Helper",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "Filter::PPI::Transform" => 0,
    "Filter::Simple" => 0,
    "PPI" => 0,
    "PPI::Transform::Sequence" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "filtered" => "v0.0.4",
    "parent" => 0
  },
  "VERSION" => "v0.0.5",
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



