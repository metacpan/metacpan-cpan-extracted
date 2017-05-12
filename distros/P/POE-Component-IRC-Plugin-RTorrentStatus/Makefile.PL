
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A PoCo-IRC plugin which prints RTorrent status messages to IRC',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '1.07'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'POE-Component-IRC-Plugin-RTorrentStatus',
  'EXE_FILES' => [
    'bin/irctor-queue'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Component::IRC::Plugin::RTorrentStatus',
  'PREREQ_PM' => {
    'Capture::Tiny' => '0',
    'DateTime' => '0',
    'DateTime::Format::Human::Duration' => '0',
    'Format::Human::Bytes' => '0',
    'List::Util' => '0',
    'POE' => '0',
    'POE::Component::IRC' => '0',
    'POE::Component::IRC::Plugin::FollowTail' => '6.22'
  },
  'VERSION' => '0.17',
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



