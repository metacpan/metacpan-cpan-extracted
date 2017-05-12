#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Net::IMAP::Simple::NB',
    'PREREQ_PM'         => { Danga::Socket => 0.52 },
    'VERSION_FROM'      => 'NB.pm',
    'ABSTRACT_FROM'     => 'NB.pm',
    'AUTHOR'            => 'Matt Sergeant, matt@sergeant.org',
);
