#!/usr/bin/perl

use 5.00405;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PM::Packages',
    VERSION_FROM      => 'lib/PM/Packages.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Test::More'  =>  0, }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/PM/Packages.pm', # retrieve abstract from module
    AUTHOR            => 'Philip Gwyn <gwyn -AT- cpan.org>',
    LICENSE           => 'perl',
);
