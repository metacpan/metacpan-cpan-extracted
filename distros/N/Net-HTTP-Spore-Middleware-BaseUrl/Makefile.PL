
use strict;
use warnings;

use 5.004;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Spore Middleware to change the base_url on the fly",
  "AUTHOR" => "Tiago Peczenyj <tiago.peczenyj\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601",
    "Test::MockObject" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Net-HTTP-Spore-Middleware-BaseUrl",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Net::HTTP::Spore::Middleware::BaseUrl",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Net::HTTP::Spore" => 0
  },
  "VERSION" => "0.02",
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



