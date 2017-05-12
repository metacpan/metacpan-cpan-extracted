
use strict;
use warnings;

BEGIN { require 5.006; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A Mouse role for setting attributes from a simple configfile',
  'AUTHOR' => 'Brandon L. Black <blblack@gmail.com>, Mark Gardner <mjgardner@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Mouse' => '0',
    'Path::Class::File' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'MouseX-SimpleConfig',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'MouseX::SimpleConfig',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Config::Any' => '0.13',
    'English' => '0',
    'Mouse' => '0.35',
    'Mouse::Role' => '0',
    'MouseX::ConfigFromFile' => '0.02'
  },
  'VERSION' => '0.11',
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



