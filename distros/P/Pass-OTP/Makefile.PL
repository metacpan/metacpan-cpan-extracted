use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Pass::OTP',
    AUTHOR         => q{Jan Baier <jan.baier@amagical.net>},
    ABSTRACT_FROM  => 'lib/Pass/OTP.pm',
    VERSION_FROM   => 'lib/Pass/OTP.pm',
    LICENSE        => 'perl_5',
    EXE_FILES      => ['bin/oathtool', 'bin/otptool'],
    MIN_PERL_VERSION => '5.014',
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'MIME::Base32' => '0',
        'Digest::HMAC' => '0',
        'Digest::SHA' => '0',
        'Math::BigInt' => '1.999806',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/baierjan/Pass-OTP-perl.git',
                web => 'https://github.com/baierjan/Pass-OTP-perl',
            },
        },
        provides => {
            'Pass::OTP' => {
                file => 'lib/Pass/OTP.pm', version => '1.801',
            },
            'Pass::OTP::URI' => {
                file => 'lib/Pass/OTP/URI.pm', version => '1.801',
            },
        }
    },
    dist  => {
        COMPRESS => 'gzip -9f', SUFFIX => 'gz',
        TARFLAGS => '--format=ustar -c -v -f',
    },
    clean => { FILES => 'Pass-OTP-*' },
);
