
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Clean subroutines with an attribute',
  'AUTHOR' => 'Mark Fowler <mark@twoshortplanks.com>',
  'BUILD_REQUIRES' => {
    'File::Spec' => '0',
    'FindBin' => '0',
    'Test::More' => '0',
    'Test::Perl::Critic' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Sub-Clean',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Sub::Clean',
  'PREREQ_PM' => {
    'Attribute::Lexical' => '0',
    'B::Hooks::EndOfScope' => '0',
    'Sub::Identify' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.01',
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



