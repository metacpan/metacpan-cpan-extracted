#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Mojolicious::Plugin::Badge',
    VERSION_FROM       => 'lib/Mojolicious/Plugin/Badge.pm',
    ABSTRACT_FROM      => 'lib/Mojolicious/Plugin/Badge.pm',
    LICENSE            => 'artistic_2',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0',},
    TEST_REQUIRES      => {'Test::More'          => '0',},
    PREREQ_PM          => {'Mojolicious'         => '9.0', 'Image::Magick' => 0},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge',
                web  => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-Badge'
            },
        },
        x_purl => 'pkg:cpan/GDT/Mojolicious-Plugin-Badge'
    },
    test  => {TESTS    => 't/*.t'},
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Mojolicious-Plugin-Badge-*'},
);
