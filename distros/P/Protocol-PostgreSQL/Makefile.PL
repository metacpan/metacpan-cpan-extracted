
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'PostgreSQL wire protocol',
  'AUTHOR' => 'Tom Molesworth <cpan@entitymodel.com>',
  'BUILD_REQUIRES' => {
    'Test::Exception' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Protocol-PostgreSQL',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Protocol::PostgreSQL',
  'PREREQ_PM' => {
    'Digest::MD5' => '0',
    'Mixin::Event::Dispatch' => '0.002',
    'POSIX' => '0',
    'Time::HiRes' => '0',
    'parent' => '0'
  },
  'VERSION' => '0.008',
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



