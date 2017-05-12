#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Template::Plugin::Digest::MD5',
    VERSION_FROM        => 'lib/Template/Plugin/Digest/MD5.pm',
    ABSTRACT            => 'TT2 interface to the MD5 Algorithm',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Template'                          => '2.0',
        'Template::Plugin'                  => '2.0',
        'Template::Stash'                   => '2.0',
        'Digest::MD5'                       => '0',

        # for testing
        'IO::File'                          => 0,
        'Test::More'                        => 0.70

    },
);
