
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Running tests with options",
  "AUTHOR" => "Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "TAP-Runner",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "TAP::Runner",
  "PREREQ_PM" => {
    "Math::Cartesian::Product" => 0,
    "Moose" => 0,
    "TAP::Harness" => 0
  },
  "VERSION" => "0.005",
  "test" => {
    "TESTS" => "t/*.t t/examples/*.t"
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



