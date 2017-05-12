#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Prancer::Session::Store::Database',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Prancer/Session/Store/Database.pm',
    'PREREQ_PM'     => {
        'Prancer'                    => '1.00',
        'Plack'                      => '0.9968',  # same version required by Web::Simple
        'Plack::Middleware::Session' => '0.23',  # require secrets
        'DBI'                        => '0',
        'DBD::Mock'                  => '0',
        'Try::Tiny'                  => '0',
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);
