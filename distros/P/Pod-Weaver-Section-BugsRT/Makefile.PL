
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Pod::Weaver::Section::BugsRT',
                       'DISTNAME' => 'Pod-Weaver-Section-BugsRT',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Michael Schout <mschout@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Module::Signature' => '0',
                                             'Test::More' => '0',
                                             'Socket' => '0'
                                           },
                       'ABSTRACT' => 'Add a BUGS pod section for rt.cpan.org',
                       'EXE_FILES' => [],
                       'VERSION' => '0.52',
                       'PREREQ_PM' => {
                                        'Pod::Weaver::Role::Section' => '0',
                                        'Moose::Autobox' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



