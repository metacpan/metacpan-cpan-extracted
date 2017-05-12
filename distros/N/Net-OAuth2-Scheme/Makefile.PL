
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Token scheme definition framework for OAuth 2.0',
  'AUTHOR' => 'Roger Crew <crew@cs.stanford.edu>',
  'BUILD_REQUIRES' => {
    'Cache::Memory' => '0',
    'HTTP::Message::PSGI' => '0',
    'HTTP::Request::Common' => '0',
    'Plack::Request' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-OAuth2-Scheme',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::OAuth2::Scheme',
  'PREREQ_PM' => {
    'Digest::SHA' => '0',
    'MIME::Base64' => '0',
    'Math::Random::MT::Auto' => '0',
    'Thread::IID' => '0.04',
    'URI::Escape' => '0'
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



