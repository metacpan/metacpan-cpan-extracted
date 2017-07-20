use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'OpenSSH::Fingerprint',
    AUTHOR           => q{ORANGE <bollwarm@ijz.me>},
    VERSION_FROM     => 'lib/OpenSSH/Fingerprint.pm',
    ABSTRACT_FROM    => 'lib/OpenSSH/Fingerprint.pm',
    LICENSE          => 'Perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    		"Crypt::Digest::SHA256"   => '0',
                "MIME::Base64"   => '0',
                "Digest::MD5"   => '0',

    },
           META_MERGE => {
          'meta-spec' => { version => 2 },
           resources   => {
            repository => {
                type => 'git',
                url  => 'https://git.oschina.net/ijz/OpenSSH-Fingerprint',
                web  => 'http://ijz.me',
                 },
            },
          },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'OpenSSH-Fingerprint-*' },
);
