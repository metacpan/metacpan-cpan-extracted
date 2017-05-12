
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A PoCo-IRC plugin which uploads select images to a mirror service',
  'AUTHOR' => 'Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'POE-Component-IRC-Plugin-ImageMirror',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Component::IRC::Plugin::ImageMirror',
  'PREREQ_PM' => {
    'HTTP::Cookies' => '0',
    'HTTP::Headers' => '0',
    'Image::ImageShack' => '0',
    'POE' => '0',
    'POE::Component::IRC' => '6.22',
    'POE::Component::IRC::Plugin::URI::Find' => '0',
    'POE::Quickie' => '0.11',
    'Try::Tiny' => '0',
    'URI::Title' => '0'
  },
  'VERSION' => '0.15',
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



