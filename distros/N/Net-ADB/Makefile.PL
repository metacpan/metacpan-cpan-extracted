#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Net::ADB',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Net/ADB.pm',
    ABSTRACT_FROM      => 'lib/Net/ADB.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [],
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0', 'Test::TCP' => '2.15'},
    PREREQ_PM          =>
        {'IO::Socket::IP' => '0', 'List::Util' => '0', 'Socket' => '0', 'Log::Any' => '0', 'Time::Piece' => '0'},
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Net-ADB/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Net-ADB',
                web  => 'https://github.com/giterlizzi/perl-Net-ADB'
            },
        },
        x_purl => 'pkg:cpan/Net-ADB'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'Net-ADB-*'},
);
