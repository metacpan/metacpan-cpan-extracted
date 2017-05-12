
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Test::CompanionClasses',
                       'DISTNAME' => 'Test-CompanionClasses',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Scalar::Util' => '0',
                                             'Test::More' => '0.94',
                                             'English' => '0',
                                             'File::Temp' => '0',
                                             'Carp' => '0'
                                           },
                       'ABSTRACT' => 'Run tests defined in companion classes',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101370',
                       'PREREQ_PM' => {
                                        'Getopt::Long' => '0',
                                        'Class::Accessor::Complex' => '0',
                                        'parent' => '0',
                                        'FindBin' => '0',
                                        'constant' => '0',
                                        'Exporter' => '0',
                                        'Test::More' => '0',
                                        'File::Find' => '0',
                                        'Data::Inherited' => '0',
                                        'UNIVERSAL::require' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



