#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SETI::Drake',
    VERSION_FROM => 'lib/SETI/Drake.pm',
    PREREQ_PM    => {},
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/SETI/Drake.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
