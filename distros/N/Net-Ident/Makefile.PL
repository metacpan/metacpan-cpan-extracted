#!/usr/bin/perl
# Makefile for Net::Ident

use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Ident',
    ABSTRACT         => 'Lookup the username on the remote end of a TCP/IP connection',
    AUTHOR           => 'Jan-Pieter Cornet <johnpc@xs4all.nl>',
    VERSION_FROM     => 'Ident.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        Socket     => '0',
        FileHandle => '0',
        Carp       => '0',
        Errno      => '0',
        Exporter   => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'IO::Socket' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => "Net-Ident-*" },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license    => ['https://dev.perl.org/licenses/'],
            bugtracker => {
                web => 'https://github.com/cpan-authors/Net-Ident/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Net-Ident.git',
                web  => 'https://github.com/cpan-authors/Net-Ident',
            },
        },
    },
);
