
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a Number::Format that ignores the system locale",
  "AUTHOR" => "Christian Walde <walde.christian\@googlemail.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::InDistDir" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Number-Format-FixedLocale",
  "EXE_FILES" => [],
  "LICENSE" => "unrestricted",
  "NAME" => "Number::Format::FixedLocale",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Number::Format" => 0,
    "base" => 0,
    "strictures" => 0
  },
  "VERSION" => "1.121780",
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



