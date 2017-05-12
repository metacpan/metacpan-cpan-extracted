
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Send SMS messages via the ArXMobile HTTP API',
  'AUTHOR' => 'Cosimo Streppone <cosimo@opera.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-SMS-ArxMobile',
  'EXE_FILES' => [
    'bin/arxmobile-send-sms',
    'bin/arxmobile-query-smsid'
  ],
  'LICENSE' => 'bsd',
  'NAME' => 'Net::SMS::ArxMobile',
  'PREREQ_PM' => {
    'Data::Dumper' => '0',
    'HTTP::Request' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Pod::Usage' => '0',
    'XML::Simple' => '0'
  },
  'VERSION' => '0.01',
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



