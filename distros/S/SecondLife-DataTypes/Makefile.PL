
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Support for parsing, working with and printing Second Life's data types",
  "AUTHOR" => "Rebecca Turner <becca\@referencethis.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SecondLife-DataTypes",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SecondLife::DataTypes",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "Math::Quaternion" => 0,
    "Regexp::Common" => 0,
    "Sub::Exporter" => 0
  },
  "VERSION" => "0.900",
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



