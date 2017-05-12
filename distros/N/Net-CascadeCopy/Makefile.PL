
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Rapidly propagate (rsync/scp/...) files to many servers in multiple locations.',
  'AUTHOR' => 'Alex White <VVu@geekfarm.org>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Test::Differences' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Net-CascadeCopy',
  'EXE_FILES' => [],
  'LICENSE' => 'bsd',
  'NAME' => 'Net::CascadeCopy',
  'PREREQ_PM' => {
    'Benchmark' => '0',
    'Log::Log4perl' => '0',
    'Mouse' => '0',
    'POSIX' => '0',
    'Proc::Queue' => '0'
  },
  'VERSION' => '0.2.6',
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



