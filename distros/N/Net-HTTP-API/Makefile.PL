
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Easily create client for net API',
  'AUTHOR' => 'franck cuny <franck@lumberjaph.net>',
  'BUILD_REQUIRES' => {
    'HTTP::Response' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-HTTP-API',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Net::HTTP::API',
  'PREREQ_PM' => {
    'HTTP::Request' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Exporter' => '0',
    'Moose::Meta::Method' => '0',
    'Moose::Role' => '0',
    'Moose::Util::MetaRole' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Types::Moose' => '0',
    'MooseX::Types::URI' => '0',
    'Try::Tiny' => '0',
    'XML::Simple' => '0',
    'YAML::Syck' => '0',
    'overload' => '0'
  },
  'VERSION' => '0.14',
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



