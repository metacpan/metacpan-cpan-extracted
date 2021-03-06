
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Resource::Pack::JSON',
                       'DISTNAME' => 'Resource-Pack-JSON',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Jesse Luehrs <doy at tozt dot net>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Resource::Pack resource for the JSON Javascript library',
                       'EXE_FILES' => [],
                       'VERSION' => '0.01',
                       'PREREQ_PM' => {
                                        'Resource::Pack' => '0.02'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



