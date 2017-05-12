
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'PostgreSQL::PLPerl::Trace',
                       'DISTNAME' => 'PostgreSQL-PLPerl-Trace',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Tim Bunce <Tim.Bunce@pobox.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Trace execution of PostgreSQL PL/Perl code statements',
                       'EXE_FILES' => [],
                       'VERSION' => '1.001',
                       'PREREQ_PM' => {},
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



