
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "An advanced SQL generator.",
  "AUTHOR" => "Aran Deltac <bluefeet\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.98",
    "Try::Tiny" => "0.11"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SQL-Abstract-Query",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SQL::Abstract::Query",
  "PREREQ_PM" => {
    "Clone" => "0.31",
    "List::MoreUtils" => "0.33",
    "List::Util" => "1.23",
    "Moose" => "2.0204",
    "MooseX::ClassAttribute" => "0.26",
    "SQL::Abstract" => "1.72",
    "SQL::Dialect" => "0.02",
    "namespace::autoclean" => "0.13"
  },
  "VERSION" => "0.03",
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



