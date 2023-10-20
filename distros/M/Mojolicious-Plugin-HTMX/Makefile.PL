#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Mojolicious::Plugin::HTMX',
    VERSION_FROM  => 'lib/Mojolicious/Plugin/HTMX.pm',
    ABSTRACT_FROM => 'lib/Mojolicious/Plugin/HTMX.pm',
    LICENSE       => 'artistic_2',
    AUTHOR        => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    PREREQ_PM     => {'Mojolicious' => '9.0'},
    META_MERGE    => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/issues',},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX',
                web  => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX'
            },
        }
    },
    test  => {TESTS    => 't/*.t'},
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Mojolicious-Plugin-HTMX-*'},
);
