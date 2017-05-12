
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Pod::Weaver::Section::CollectWithAutoDoc',
                       'DISTNAME' => 'Pod-Weaver-Section-CollectWithAutoDoc',
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
                       'ABSTRACT' => 'Section to gather specific commands and add auto-generated documentation',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100980',
                       'PREREQ_PM' => {
                                        'Moose::Autobox' => '0',
                                        'Pod::Elemental::Element::Pod5::Verbatim' => '0',
                                        'Pod::Elemental::Element::Pod5::Command' => '0',
                                        'Pod::Elemental::Element::Pod5::Ordinary' => '0',
                                        'Pod::Weaver::Role::Preparer' => '0',
                                        'Sub::Documentation' => '0',
                                        'Pod::Weaver::Section::Collect' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



