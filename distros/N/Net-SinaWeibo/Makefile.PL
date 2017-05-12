
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A simple and lightweight OAuth api for SinaWeibo',
  'AUTHOR' => 'Pan Fan(nightsailer) <nightsailer@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.9'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-SinaWeibo',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::SinaWeibo',
  'PREREQ_PM' => {
    'HTTP::Request::Common' => '0',
    'JSON' => '0',
    'OAuth::Lite' => '1.27'
  },
  'VERSION' => '0.003',
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



