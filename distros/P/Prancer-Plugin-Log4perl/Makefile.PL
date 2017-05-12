#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Prancer::Plugin::Log4perl',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Prancer/Plugin/Log4perl.pm',
    'PREREQ_PM'     => {
        'Prancer'       => '1.00',
        'Log::Log4perl' => '0',
        'Log::Dispatch' => '0',
        'Try::Tiny'     => '0',
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);
