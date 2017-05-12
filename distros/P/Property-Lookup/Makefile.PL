
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Property::Lookup',
                       'DISTNAME' => 'Property-Lookup',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0.94',
                                             'Scalar::Util' => '0',
                                             'English' => '0',
                                             'File::Find' => '0',
                                             'FindBin' => '0',
                                             'File::Temp' => '0',
                                             'Carp' => '0'
                                           },
                       'ABSTRACT' => 'Object property lookup across multiple layers',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101400',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'Error::Hierarchy::Internal::CustomMessage' => '0',
                                        'Class::Accessor::Constructor' => '0',
                                        'parent' => '0',
                                        'YAML' => '0',
                                        'Error::Hierarchy::Util' => '0',
                                        'File::Basename' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



