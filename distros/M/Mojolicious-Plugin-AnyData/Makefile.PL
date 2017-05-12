use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Use and handle any data like a database source in test mode',
  'AUTHOR' => 'Alexander Ponomarev <shootnix@cpan.org>',
  'BUILD_REQUIRES' => {
    'DBD::AnyData' => '0',
    'English' => '0',
    'Module::Build' => '0.38',
    'Mojolicious::Lite' => '0',
    'Test::Mojo' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.38'
  },
  'DISTNAME' => 'Mojolicious-Plugin-AnyData',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Mojolicious::Plugin::AnyData',
  'PREREQ_PM' => {
    'DBI' => '0',
    'DBD::AnyData' => '0',
    'Mojo::Base' => '0'
  },
  'VERSION' => '1.20',
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
