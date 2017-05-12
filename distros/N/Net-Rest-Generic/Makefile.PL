use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Rest::Generic',
    AUTHOR           => q{Sebastian Green-Husted,Shane Utt <ricecake@tfm.nu>},
    VERSION_FROM     => 'lib/Net/Rest/Generic.pm',
    ABSTRACT_FROM    => 'lib/Net/Rest/Generic.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
	'Want'           => 1,
	'Test::Deep'     => 1,
        'Test::More'     => 1,
	'URI'            => 1,
	'LWP::UserAgent' => 1,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Rest-Generic-*' },
);
