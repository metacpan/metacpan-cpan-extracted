use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::SecurityCenter',
    AUTHOR           => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM     => 'lib/Net/SecurityCenter.pm',
    ABSTRACT_FROM    => 'lib/Net/SecurityCenter.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [
        'bin/sc-api'
    ],
    MIN_PERL_VERSION => 5.008,
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
        'HTTP::Daemon' => '0',
    },
    PREREQ_PM => {
        'JSON'           => '0',
        'Time::Piece'    => '0',
        'LWP::UserAgent' => 6.04,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Net-SecurityCenter',
                web  => 'https://github.com/giterlizzi/perl-Net-SecurityCenter'
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-SecurityCenter-*' },
);
