
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Use Markapl as Tatsumaki\'s template system.',
  'AUTHOR' => 'Gea-Suan Lin <gslin@gslin.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Tatsumaki-Template-Markapl',
  'EXE_FILES' => [],
  'LICENSE' => 'bsd',
  'NAME' => 'Tatsumaki::Template::Markapl',
  'PREREQ_PM' => {
    'Any::Moose' => '0',
    'Plack::Util' => '0',
    'Sub::Install' => '0',
    'Tatsumaki::Template' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.3',
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



