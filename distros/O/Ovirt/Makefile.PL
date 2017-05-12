use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ovirt',
    AUTHOR           => q{"Heince Kurniawan" <"heince@cpan.org">},
    VERSION_FROM     => 'lib/Ovirt.pm',
    ABSTRACT_FROM    => 'lib/Ovirt.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent'        => 5.8,
        'LWP::Protocol::https'  => 5,
        'Moo'                   => 2,
        'XML::LibXML'           => 2,
        'XML::Hash::XS'         => 0,
        'Log::Log4perl'         => 1,
        'URI::Escape'           => 0,
        'JSON'                  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ovirt-*' },
);
