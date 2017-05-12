
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'AYOUNG\'s default Pod::Weaver config',
  'AUTHOR' => 'Alan Young <harleypig@gmail.com>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Path::Class' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94',
    'Test::Perl::Critic::Progressive' => '0',
    'Try::Tiny' => '0',
    'perl' => '5.004'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'Pod-Weaver-PluginBundle-AYOUNG',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Pod::Weaver::PluginBundle::AYOUNG',
  'PREREQ_PM' => {
    'Pod::Weaver::Config::Assembler' => '0'
  },
  'VERSION' => '0.14',
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



