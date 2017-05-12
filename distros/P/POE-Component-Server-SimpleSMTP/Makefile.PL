
use strict;
use warnings;

BEGIN { require v5.6.0; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A simple to use POE SMTP Server.',
  'AUTHOR' => 'Chris Williams <chris@bingosnet.co.uk>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'POE-Component-Server-SimpleSMTP',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Component::Server::SimpleSMTP',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Email::Address' => '1.886',
    'Email::MessageID' => '1.4',
    'Email::Simple' => '1.998',
    'Email::Simple::Creator' => '1.41',
    'POE' => '1.294',
    'POE::Component::Client::DNS' => '0.99',
    'POE::Component::Client::DNSBL' => '0.08',
    'POE::Component::Client::SMTP' => '0.18',
    'POE::Component::Pluggable' => '0.03',
    'POE::Filter::Line' => '0',
    'POE::Filter::Transparent::SMTP' => '0',
    'POE::Wheel::ReadWrite' => '0',
    'POE::Wheel::SocketFactory' => '0',
    'POSIX' => '0',
    'Socket' => '0',
    'Storable' => '0'
  },
  'VERSION' => '1.50',
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



