use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Toolkit for CLI Automation',
  'AUTHOR' => 'Oliver Gorwits <oliver@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88',
    'warnings' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Net-CLI-Interact',
  'LICENSE' => 'perl',
  'NAME' => 'Net::CLI::Interact',
  'PREREQ_PM' => {
    'Class::Load' => '0',
    'Class::Mix' => '0',
    'File::Basename' => '0',
    'FileHandle' => '0',
    'IPC::Run' => '0',
    'List::Util' => '0',
    'Log::Dispatch::Config' => '0',
    'Log::Dispatch::Configurator::Any' => '0',
    'Moo' => '0',
    'Moo::Role' => '0',
    'MooX::Types::MooseLike::Base' => '0',
    'Net::Telnet' => '0',
    'POSIX' => '0',
    'Path::Class' => '0',
    'Sub::Quote' => '0',
    'Time::HiRes' => '0',
    'strict' => '0'
  },
  'VERSION' => '2.200006',
  'test' => {
    'TESTS' => 't/*.t'
  },
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

if ( $^O =~ m/^(?!Win32)/ ) {
  $WriteMakefileArgs{CONFIGURE_REQUIRES}{'ExtUtils::CBuilder'} = 0;

  eval 'require ExtUtils::CBuilder;';
  if (not $@) {
    my $builder = ExtUtils::CBuilder->new( quiet => 1 );
    if ($builder->have_compiler) {
        $WriteMakefileArgs{PREREQ_PM}{'IO::Pty'} = '0';
    }
  }
}

WriteMakefile(%WriteMakefileArgs);
