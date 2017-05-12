
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Term::Shell::Enhanced',
                       'DISTNAME' => 'Term-Shell-Enhanced',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Scalar::Util' => '0',
                                             'Test::More' => '0.94',
                                             'English' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0',
                                             'Carp' => '0'
                                           },
                       'ABSTRACT' => 'More functionality for Term::Shell',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101420',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'Getopt::Long' => '0',
                                        'parent' => '0',
                                        'Term::Shell' => '0',
                                        'Data::Inherited' => '0',
                                        'Cwd' => '0',
                                        'Sys::Hostname' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



