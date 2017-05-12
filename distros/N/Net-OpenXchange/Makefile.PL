
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Object-oriented interface to OpenXchange groupware',
  'AUTHOR' => 'Maximilian Gass <maximilian.gass@credativ.de>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::Moose' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-OpenXchange',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::OpenXchange',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Dump' => '0',
    'HTTP::Request::Common' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Modern::Perl' => '0',
    'Module::Pluggable' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Email' => '0',
    'MooseX::Types::Moose' => '0',
    'Readonly' => '0',
    'Throwable::Error' => '0',
    'Try::Tiny' => '0',
    'URI' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.001',
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



