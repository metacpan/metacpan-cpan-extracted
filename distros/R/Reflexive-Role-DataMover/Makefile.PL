
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a composable behavior for moving data between Reflex::Streams",
  "AUTHOR" => "Nicholas R. Perez <nperez\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "IO::All" => 0,
    "Moose" => 0,
    "Reflex::Base" => 0,
    "Reflex::Stream" => 0,
    "Test::More" => 0,
    "Text::Lorem" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Reflexive-Role-DataMover",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Reflexive::Role::DataMover",
  "PREREQ_PM" => {
    "MooseX::Params::Validate" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "Reflex" => "0.098",
    "Reflex::Callbacks" => 0,
    "Reflex::Role" => 0,
    "Reflex::Role::Collectible" => 0,
    "Test::More" => "0.92",
    "namespace::autoclean" => 0
  },
  "VERSION" => "1.122130",
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



