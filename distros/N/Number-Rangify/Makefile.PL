
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Number::Rangify',
                       'DISTNAME' => 'Number-Rangify',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Optimize a list of values into ranges',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100860',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'English' => '0',
                                        'Exporter' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Set::IntRange' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



