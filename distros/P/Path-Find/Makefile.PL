#!/usr/bin/perl

use strict;
use warnings;

use 5.00503;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Path::Find',
    VERSION_FROM      => 'lib/Path/Find.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                'Test::More'    => 0, 
                'File::Spec'    => 3,
                'Text::Glob'    => 0.11,
                'Scalar::Util'  => 1.5
        },
    ABSTRACT_FROM     => 'lib/Path/Find.pm', # retrieve abstract from module
    AUTHOR            => 'Philip Gwyn <gwyn@cpan.org>',
    LICENSE           => 'perl',
);
