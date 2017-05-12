
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'utilities to build requests for the notifo.com service',
  'AUTHOR' => 'Pedro Melo <melo@simplicidade.org>',
  'BUILD_REQUIRES' => {
    'Test::Deep' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Protocol-Notifo',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Protocol::Notifo',
  'PREREQ_PM' => {
    'Carp' => '0',
    'File::HomeDir' => '0',
    'File::Spec::Functions' => '0',
    'JSON' => '2.26',
    'MIME::Base64' => '0',
    'URI' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.004',
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



