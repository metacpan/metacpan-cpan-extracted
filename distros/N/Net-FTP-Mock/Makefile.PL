
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'test code using Net::FTP without having an FTP server',
  'AUTHOR' => 'Christian Walde <mithaldu@yahoo.de>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'Test::Most' => '0',
    'Test::Simple' => '0.96'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-FTP-Mock',
  'EXE_FILES' => [],
  'LICENSE' => 'unrestricted',
  'NAME' => 'Net::FTP::Mock',
  'PREREQ_PM' => {
    'File::Copy' => '0',
    'Moose' => '0'
  },
  'VERSION' => '0.103300',
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



