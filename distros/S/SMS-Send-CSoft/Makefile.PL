
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'SMS::Send driver to send via the Connection Software service',
  'AUTHOR' => 'Mark Hindess <soft-cpan@temporalanomaly.com>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'LWP::Protocol::PSGI' => '0',
    'LWP::Protocol::https' => '0',
    'Plack::Request' => '0',
    'SMS::Send' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'SMS-Send-CSoft',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'SMS::Send::CSoft',
  'PREREQ_PM' => {
    'HTTP::Request::Common' => '0',
    'LWP::UserAgent' => '0',
    'SMS::Send::Driver' => '0'
  },
  'VERSION' => '1.111490',
  'test' => {
    'TESTS' => 't/*.t'
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



