
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A PoCo-IRC plugin which provides access to a MegaHAL conversation simulator.",
  "AUTHOR" => "Hinrik \303\226rn Sigur\303\260sson <hinrik.sig\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Script" => "1.07"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "POE-Component-IRC-Plugin-MegaHAL",
  "EXE_FILES" => [
    "bin/irchal-seed"
  ],
  "LICENSE" => "perl",
  "NAME" => "POE::Component::IRC::Plugin::MegaHAL",
  "PREREQ_PM" => {
    "IRC::Utils" => "0.05",
    "POE::Component::AI::MegaHAL" => 0,
    "POE::Component::IRC" => "6.22"
  },
  "VERSION" => "0.46",
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



