use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
               NAME          => 'POE::Filter::BigBrother',
               LICENSE       => 'perl',
               AUTHOR        => 'Yves Blusseau',
               VERSION_FROM  => 'lib/POE/Filter/BigBrother.pm',
               ABSTRACT_FROM => 'lib/POE/Filter/BigBrother.pm',
               PREREQ_PM     => {
                              'POE::Filter' => '0.38',
                              'Test::More'  => '0.60',
                            },
               PL_FILES => {},
               dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
               clean => { FILES => 'POE-Filter-BigBrother-*' }
             );
