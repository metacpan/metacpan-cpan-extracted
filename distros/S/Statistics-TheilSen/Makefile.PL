use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Statistics::TheilSen',
    AUTHOR           => q{Jimi Wills <jimi@webu.co.uk>},
    VERSION_FROM     => 'lib/Statistics/TheilSen.pm',
    ABSTRACT_FROM    => 'lib/Statistics/TheilSen.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
	'Statistics::QuickMedian' => 0.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Statistics-TheilSen-*' },
);
