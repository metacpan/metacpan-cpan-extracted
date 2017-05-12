
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A PSGI compatible REST framework',
  'AUTHOR' => 'Oliver Charles',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Sloth',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Sloth',
  'PREREQ_PM' => {
    'Data::TreeValidator' => '0.03',
    'HTTP::Request::Common' => '5.824',
    'HTTP::Status' => '5.817',
    'HTTP::Throwable' => '0.010',
    'Module::Pluggable' => '3.9',
    'Moose' => '1.21',
    'MooseX::NonMoose' => '0.17',
    'Path::Router' => '0.10',
    'Plack' => '0.9967',
    'Plack::Test' => '0.9967',
    'REST::Utils' => '0.04',
    'Scalar::Util' => '1.23',
    'String::CamelCase' => '0.02',
    'Test::Fatal' => '0.003',
    'Test::More' => '0.96',
    'Test::Routine' => '0.004',
    'Try::Tiny' => '0.09',
    'aliased' => '0.30',
    'namespace::autoclean' => '0.11'
  },
  'VERSION' => '0.05',
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



