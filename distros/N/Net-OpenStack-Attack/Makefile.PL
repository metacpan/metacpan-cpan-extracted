
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tools for stress testing an OpenStack deployment.",
  "AUTHOR" => "William Wolf <throughnothing\@gmail.com>, Naveed Massjouni <naveedm9\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Net-OpenStack-Attack",
  "EXE_FILES" => [
    "bin/stackattack"
  ],
  "LICENSE" => "perl",
  "NAME" => "Net::OpenStack::Attack",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "App::Rad" => 0,
    "HTTP::Async" => "0.10",
    "HTTP::Request" => 0,
    "JSON" => 0,
    "Net::HTTPS::NB" => 0,
    "Net::OpenStack::Compute" => "1.0401",
    "Time::SoFar" => 0
  },
  "VERSION" => "1.0500",
  "test" => {
    "TESTS" => ""
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



