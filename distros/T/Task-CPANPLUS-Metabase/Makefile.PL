
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Install everything for CPANPLUS to use Metabase',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Task-CPANPLUS-Metabase',
  'EXE_FILES' => [
    'bin/metabase_cpanp'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Task::CPANPLUS::Metabase',
  'PREREQ_PM' => {
    'CPANPLUS' => '0.9007',
    'Metabase::Fact' => '0.017',
    'Module::Load::Conditional' => '0',
    'Term::UI' => '0',
    'Test::Reporter' => '1.57',
    'Test::Reporter::Transport::Metabase' => '1.999008'
  },
  'VERSION' => '0.08',
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



