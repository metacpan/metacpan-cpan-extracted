
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'PostgreSQL::PLPerl::Call',
                       'DISTNAME' => 'PostgreSQL-PLPerl-Call',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Tim Bunce <Tim.Bunce@pobox.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Simple interface for calling SQL functions from PostgreSQL PL/Perl',
                       'EXE_FILES' => [],
                       'VERSION' => '1.006',
                       'PREREQ_PM' => {
                                        'DBI' => '1.605'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



