
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'It\'s a simple way to dump and backup data from redis-server',
  'AUTHOR' => 'Thiago Rondon <thiago@nsms.com.br>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'Exporter' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'IO::String' => '0',
    'POSIX' => '0',
    'Test::Deep' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Redis-Dump',
  'EXE_FILES' => [
    'bin/redis-config',
    'bin/redis-dump',
    'bin/redis-restore',
    'bin/redis-config',
    'bin/redis-dump',
    'bin/redis-restore'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Redis::Dump',
  'PREREQ_PM' => {
    'JSON' => '0',
    'Moose' => '0',
    'MooseX::Getopt' => '0',
    'MooseX::Types::Path::Class' => '0',
    'Redis' => '1.904'
  },
  'VERSION' => '0.016',
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



