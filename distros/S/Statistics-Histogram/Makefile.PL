
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Create a standard histogram for command-line display',
  'AUTHOR' => 'Douglas Webb <doug.webb@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Statistics-Histogram',
  'EXE_FILES' => [
    'bin/histogram'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Statistics::Histogram',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'Getopt::Long' => '0',
    'Statistics::Descriptive' => '0',
    'constant' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.2',
  'test' => {
    'TESTS' => ''
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



