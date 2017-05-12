
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'An interface to Rackspace Email Notes.',
  'AUTHOR' => 'Naveed Massjouni <naveedm9@gmail.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Net-Rackspace-Notes',
  'EXE_FILES' => [
    'bin/racknotes'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Net::Rackspace::Notes',
  'PREREQ_PM' => {
    'App::Rad' => '1.04',
    'HTTP::Request' => '0',
    'JSON' => '2.22',
    'LWP::UserAgent' => '5.835',
    'Moose' => '1.12',
    'Parallel::ForkManager' => '0.7.6',
    'Term::ReadPassword' => '0.11'
  },
  'VERSION' => '1.0000',
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



