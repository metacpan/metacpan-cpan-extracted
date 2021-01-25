use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::OpenVAS',
    AUTHOR           => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM     => 'lib/Net/OpenVAS.pm',
    ABSTRACT_FROM    => 'lib/Net/OpenVAS.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => [],
    MIN_PERL_VERSION => 5.010,
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
    },
    PREREQ_PM => {
        'XML::Hash::XS'   => '0',
        'IO::Socket::SSL' => '0'
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Net-OpenVAS',
                web  => 'https://github.com/giterlizzi/perl-Net-OpenVAS'
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-OpenVAS-*' },
);
