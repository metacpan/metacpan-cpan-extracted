
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Install the things to make a CPAN Testers smokebox',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Task-CPAN-SmokeBox',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Task::CPAN::SmokeBox',
  'PREREQ_PM' => {
    'App::Metabase::Relayd' => '0.22',
    'App::SmokeBox::Mini' => '0.40',
    'App::SmokeBox::Mini::Plugin::IRC' => '0.06',
    'App::SmokeBox::Mini::Plugin::Stats' => '0.08',
    'App::SmokeBrew' => '0.28',
    'App::SmokeBrew::Plugin::BINGOS' => '0.04'
  },
  'VERSION' => '0.04',
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



