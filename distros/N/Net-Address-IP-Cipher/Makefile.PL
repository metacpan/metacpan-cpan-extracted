use 5.12.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME             => 'Net::Address::IP::Cipher',
    AUTHOR           => q{Hugo Salgado <hsalgado@vulcano.cl>},
    VERSION_FROM     => 'lib/Net/Address/IP/Cipher.pm',
    ABSTRACT_FROM    => 'lib/Net/Address/IP/Cipher.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.12.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::IP'            => 0,
        'MIME::Base64'       => 0,
        'Crypt::PBKDF2'      => 0,
        'Crypt::Cipher::AES' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Address-IP-Cipher-*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/huguei/p5-Net-Address-IP-Cipher.git',
                web  => 'https://github.com/huguei/p5-Net-Address-IP-Cipher',
            },
        },
    },
);
