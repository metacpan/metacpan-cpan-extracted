
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Object for BridgeIDs (priority/MAC combos)",
  "AUTHOR" => "Brendan Byrd <BBYRD\@CPAN.org>",
  "BUILD_REQUIRES" => {
    "Test::CheckDeps" => "0.002",
    "Test::UseAllModules" => "0.10"
  },
  "CONFIGURE_REQUIRES" => {},
  "DISTNAME" => "NetAddr-BridgeID",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "NetAddr::BridgeID",
  "PREREQ_PM" => {
    "Moo" => "0.009001",
    "MooX::Types::CLike" => "0.90",
    "MooX::Types::MooseLike" => "0.03",
    "NetAddr::MAC" => "0.7",
    "sanity" => "0.94"
  },
  "VERSION" => "0.97",
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



