
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl extension for accessing pachube.com',
  'AUTHOR' => 'Mark Hindess <soft-pachube@temporalanomaly.com>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::More' => '0',
    'XML::SAX' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-Pachube',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::Pachube',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor::Fast' => '0',
    'HTTP::Request' => '0',
    'LWP::UserAgent' => '0',
    'XML::Simple' => '0'
  },
  'VERSION' => '1.102900',
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



