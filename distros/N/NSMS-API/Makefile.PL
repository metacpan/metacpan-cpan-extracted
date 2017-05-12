
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'API para enviar SMS através da NSMS (http://www.nsms.com.br/)',
  'AUTHOR' => 'Thiago Rondon <thiago@nsms.com.br>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Mock::LWP::Dispatch' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'NSMS-API',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'NSMS::API',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Dumper' => '0',
    'HTTP::Request::Common' => '0',
    'HTTP::Response' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'URI::Escape' => '0',
    'utf8' => '0'
  },
  'VERSION' => '0.006',
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



