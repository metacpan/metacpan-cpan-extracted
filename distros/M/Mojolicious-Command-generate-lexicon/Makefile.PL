#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => 'http://github.com/und3f/mojoliciousx-lexicon',
        },
    }
};

WriteMakefile(
    NAME         => 'Mojolicious::Command::generate::lexicon',
    VERSION_FROM => 'lib/Mojolicious/Command/generate/lexicon.pm',
    AUTHOR       => 'Serhii Zasenko <undef@cpan.org>',
    PREREQ_PM    => {
        'File::Find'     => 0,
        'Getopt::Long'   => 0,
        'Mojolicious'    => '9.21',
        'String::Escape' => 0,
    },
    TEST_REQUIRES => {
        'Cwd'        => 0,
        'File::Temp' => 0,
        'File::Copy' => 0,
        'Test::More' => 0,
        'FindBin'    => 0,
    },
    test => { TESTS => 't/*.t t/*/*.t t/*/*/*.t' }
);
