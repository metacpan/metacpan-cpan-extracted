
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A POE::Component::IRC plugin for IRC based DNS queries",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "POE-Component-IRC-Plugin-QueryDNS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "POE::Component::IRC::Plugin::QueryDNS",
  "PREREQ_PM" => {
    "Net::IP::Minimal" => 0,
    "POE" => "1.004",
    "POE::Component::Client::DNS" => 1,
    "POE::Component::IRC" => "5.7",
    "POE::Component::IRC::Common" => "5.16",
    "POE::Component::IRC::Plugin" => "0.1"
  },
  "VERSION" => "1.04",
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



