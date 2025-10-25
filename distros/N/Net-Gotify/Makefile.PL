#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Net::Gotify',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Net/Gotify.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {'Moo'                 => '0', 'HTTP::Tiny' => '0', 'JSON::PP' => '0'},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Net-Gotify/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Net-Gotify',
                web  => 'https://github.com/giterlizzi/perl-Net-Gotify'
            },
        },
        x_purl => 'pkg:cpan/GDT/Net-Gotify'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Net-Gotify-*'},
);
