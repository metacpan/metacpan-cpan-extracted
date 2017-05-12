use strict;
use warnings;
use ExtUtils::MakeMaker 6.31;

BEGIN {
    warn "MojoX::Dispatcher::Qooxdoo::Jsonrpc is DEPRECATED. Please switch to using Mojolicious::Plugin::Qooxdoo.\n" unless $ENV{DISABLE_DEPRECATION_WARNING_MPQ};
}

my %WriteMakefileArgs = (
  'ABSTRACT' => 'dispatch Qooxdoo applications with Mojo',
  'AUTHOR' => 'Matthias Bloch <matthias at puffin ch>',
  'BUILD_REQUIRES' => {
      'Test::More' => 0,
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'MojoX-Dispatcher-Qooxdoo-Jsonrpc',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'MojoX::Dispatcher::Qooxdoo::Jsonrpc',
  'PREREQ_PM' => {
    'Mojolicious' => '5.0'
  },
  'VERSION' => '0.96',
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
