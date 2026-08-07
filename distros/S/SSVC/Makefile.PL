#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'SSVC',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/SSVC.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-SSVC/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-SSVC',
                web  => 'https://github.com/giterlizzi/perl-SSVC'
            },
        },
        x_purl => 'pkg:cpan/SSVC'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'SSVC-*'},
);
