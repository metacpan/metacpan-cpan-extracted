
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Split any SQL code into atomic statements',
  'AUTHOR' => 'Emanuele Zeppieri <emazep@cpan.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Exception' => '0.27',
    'Test::More' => '0.7'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'SQL-SplitStatement',
  'EXE_FILES' => [
    'bin/sql-split'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'SQL::SplitStatement',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor::Fast' => '0',
    'Getopt::Long' => '0',
    'List::MoreUtils' => '0',
    'Pod::Usage' => '0',
    'Regexp::Common' => '0',
    'SQL::Tokenizer' => '0.22',
    'constant' => '0'
  },
  'VERSION' => '1.00020',
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



