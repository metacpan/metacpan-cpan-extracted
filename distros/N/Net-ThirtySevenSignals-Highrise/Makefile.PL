
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl extension for talking 37Signals\' Highrise API',
  'AUTHOR' => 'Danny Sadinoff <danny@sadinoff.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Net-ThirtySevenSignals-Highrise',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::ThirtySevenSignals::Highrise',
  'PREREQ_PM' => {
    'HTTP::Request' => '0',
    'LWP::UserAgent' => '0',
    'Log::Log4perl' => '0',
    'Test::More' => '0',
    'URI' => '0',
    'XML::Simple' => '0'
  },
  'VERSION' => '0.03',
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



