
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Flexible apachectl style control for servers',
  'AUTHOR' => 'Jonathan Swartz <swartz@pobox.com>',
  'BUILD_REQUIRES' => {
    'File::Path' => '0',
    'Guard' => '0.5',
    'HTTP::Server::Simple' => '0.28',
    'Net::Server' => '0',
    'POSIX' => '0',
    'Test::Class' => '0',
    'Test::Log::Dispatch' => '0',
    'Test::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Server-Control',
  'EXE_FILES' => [
    'bin/apachectlp',
    'bin/serverctlp'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Server::Control',
  'PREREQ_PM' => {
    'Apache::ConfigParser' => '1.01',
    'Capture::Tiny' => '0',
    'File::Slurp' => '9999.13',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'File::Which' => '0',
    'Getopt::Long' => '0',
    'Hash::MoreUtils' => '0',
    'IO::Socket' => '0',
    'IPC::System::Simple' => '1.18',
    'List::MoreUtils' => '0.13',
    'Log::Any::Adapter::Dispatch' => '0.05',
    'Moose' => '0.66',
    'MooseX::StrictConstructor' => '0.08',
    'Pod::Usage' => '0',
    'Proc::ProcessTable' => '0.39',
    'Time::HiRes' => '0',
    'YAML::Any' => '0'
  },
  'VERSION' => '0.20',
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



