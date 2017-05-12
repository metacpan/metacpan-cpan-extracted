#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Parse::CPAN::Distributions',
    VERSION_FROM        => 'lib/Parse/CPAN/Distributions.pm',
    ABSTRACT	        => 'Provides an index for current CPAN distributions',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'CPAN::DistnameInfo'    => '0',
        'File::Basename'        => '0',
        'File::Path'            => '0',
        'File::Slurp'           => '0',
        'File::Temp'            => '0',
        'IO::File'              => '0',
        'IO::Zlib'              => '0',
        'LWP::UserAgent'        => '0',
        'version'               => '0',

        # build/test prereqs
        'Test::More'            => '0.70',
        'IO::File'              => '0'
    }
);
