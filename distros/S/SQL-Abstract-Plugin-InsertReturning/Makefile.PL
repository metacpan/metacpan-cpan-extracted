
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'SQL::Abstract::Plugin::InsertReturning',
                       'DISTNAME' => 'SQL-Abstract-Plugin-InsertReturning',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Oliver Charles <oliver.g.charles@googlemail.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Augment SQL::Abstract->insert with support for returning data',
                       'EXE_FILES' => [],
                       'VERSION' => '0.05',
                       'PREREQ_PM' => {
                                        'SQL::Abstract' => '1.61',
                                        'Test::More' => '0.88',
                                        'Sub::Exporter' => '0.9'
                                      },
                       'LICENSE' => undef
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



