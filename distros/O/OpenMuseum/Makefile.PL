use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME             => 'OpenMuseum',
              AUTHOR           => q{Samuel W. Flint <linuxkid@linux.com>},
              VERSION_FROM     => 'lib/OpenMuseum.pm',
              ABSTRACT_FROM    => 'lib/OpenMuseum.pm',
              LICENSE          => 'GPL_2',
              PL_FILES         => {},
              MIN_PERL_VERSION => 5.006,
              CONFIGURE_REQUIRES => {
                                     'ExtUtils::MakeMaker' => 0,
                                    },
              BUILD_REQUIRES => {
                                 'Test::More' => 0,
                                },
              PREREQ_PM => {
                            'DBI'                 => 1.0,
                            'DBD::mysql'          => 4.022
                            #'ABC'              => 1.6,
                            #'Foo::Bar::Module' => 5.0401,
                           },
              dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean => { FILES => 'OpenMuseum-*' },
);
