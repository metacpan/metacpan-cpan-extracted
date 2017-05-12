
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Net::ClientServer',
                       'DISTNAME' => 'Net-ClientServer',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
                       'BUILD_REQUIRES' => {
                                             'Test::Most' => '0'
                                           },
                       'ABSTRACT' => 'A client/server platform for IPC on localhost',
                       'EXE_FILES' => [],
                       'VERSION' => '0.0007',
                       'PREREQ_PM' => {
                                        'File::HomeDir' => '0',
                                        'Any::Moose' => '0',
                                        'IO::Socket::INET' => '0',
                                        'Path::Class' => '0',
                                        'Daemon::Daemonize' => '0'
                                      },
                       'LICENSE' => 'perl'
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



