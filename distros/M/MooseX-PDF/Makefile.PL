#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MooseX::PDF',
    AUTHOR              => q{Hamid Afshar (Hamster) <hamster@cpan.org>},
    VERSION_FROM        => 'lib/MooseX/PDF.pm',
    ABSTRACT            => 'Create PDF files with Moose using Template Toolkit templates',
    LICENSE             => 'Artistic_2_0',
    PL_FILES            => {},
    NO_META             => 1,

    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'           => 0
    },

    BUILD_REQUIRES      => {
        'IO::File'                      => 0,
        'Test::Most'                    => 0
    },

    PREREQ_PM           => {
        'File::chdir'                   => 0,
        'IO::CaptureOutput'             => 0,
        'Moose::Role'                   => 0,
        'PDF::Reuse'                    => 0,
        'Template'                      => 0
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooseX-PDF-*' },
);
