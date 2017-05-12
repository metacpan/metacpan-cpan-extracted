
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Pod::Elemental::Transformer::Include',
                       'DISTNAME' => 'Pod-Elemental-Transformer-Include',
                       'AUTHOR' => 'Adam Flott <adam@npjh.com>',
                       'ABSTRACT' => 'include output via files and commands',
                       'EXE_FILES' => [],
                       'VERSION' => '1.001',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Pod::Elemental::Transformer' => '0',
                                        'File::Slurp' => '0'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



