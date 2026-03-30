use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDF::Sign',
    AUTHOR           => 'Massimiliano Citterio',
    VERSION_FROM     => 'lib/PDF/Sign.pm',
    ABSTRACT_FROM    => 'lib/PDF/Sign.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM => {
        'Exporter'              => 0,
        'Cwd'                   => 0,
        'POSIX'                 => 0,
        'MIME::Base64'          => 0,
        'File::Slurp'           => 0,

    },
    # PDF::API2 or PDF::Builder — one required, checked at runtime in BEGIN
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'cvs',
                url  => '',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'PDF::API2'        => 0,
                    'LWP::UserAgent'   => 0,
                },
                suggests => {
                    'PDF::Builder'     => 0,
                },
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PDF-Sign-*' },
);
