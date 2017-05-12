
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'MooseX::LexicalRoleApplication',
                       'DISTNAME' => 'MooseX-LexicalRoleApplication',
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
                       'ABSTRACT' => 'Apply roles for a lexical scope only',
                       'EXE_FILES' => [],
                       'VERSION' => '0.03',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'namespace::clean' => '0',
                                        'Test::More' => '0.89',
                                        'Scope::Guard' => '0',
                                        'namespace::autoclean' => '0',
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Task::Weaken' => '0',
                                        'Moose' => '0.94'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



