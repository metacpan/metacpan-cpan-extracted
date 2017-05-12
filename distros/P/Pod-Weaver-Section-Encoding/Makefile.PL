
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Pod::Weaver::Section::Encoding',
                       'DISTNAME' => 'Pod-Weaver-Section-Encoding',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Keedi Kim - 김도형 <keedi@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'add a encoding pod tag with encoding (for your Perl module)',
                       'EXE_FILES' => [],
                       'VERSION' => '0.100830',
                       'PREREQ_PM' => {
                                        'Test::More' => '0',
                                        'Pod::Elemental::Element::Pod5::Ordinary' => '0',
                                        'Pod::Elemental::Element::Pod5::Command' => '0',
                                        'Pod::Weaver::Role::Section' => '0',
                                        'Moose::Autobox' => '0',
                                        'Pod::Elemental::Element::Nested' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



