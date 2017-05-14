
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plack application for SOAP::WSDL Server modules",
  "AUTHOR" => "Andreas Stricker <andy\@knitter.ch>",
  "BUILD_REQUIRES" => {
    "Plack::Test" => 0,
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SOAP-WSDL-Server-Plack",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SOAP::WSDL::Server::Plack",
  "PREREQ_PM" => {
    "HTTP::Headers" => 0,
    "HTTP::Request" => 0,
    "Moose" => 0,
    "MooseX::FollowPBP" => 0,
    "Plack::Request" => 0,
    "Plack::Util" => 0,
    "SOAP::WSDL" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.006",
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



