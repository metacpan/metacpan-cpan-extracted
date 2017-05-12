
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Add colors to DNA and RNA sequences in terminal output',
  'AUTHOR' => 'Ryan C. Thompson <rct@thompsonclan.org>',
  'BUILD_REQUIRES' => {
    'Algorithm::Numerical::Shuffle' => '0',
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'List::AllUtils' => '0',
    'Scalar::Util' => '0',
    'String::Random' => '0',
    'Term::ANSIColor' => '2.01',
    'Test::More' => '0.94',
    'perl' => '5.004'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Term-DNAColor',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Term::DNAColor',
  'PREREQ_PM' => {
    'Exporter::Simple' => '0',
    'Memoize' => '0',
    'Term::ANSIColor::Print' => '0',
    'utf8' => '0'
  },
  'VERSION' => '0.110460',
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



