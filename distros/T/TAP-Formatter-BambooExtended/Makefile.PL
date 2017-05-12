#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'TAP::Formatter::BambooExtended',
    'AUTHOR'        => 'Paul Lockaby <plockaby AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/TAP/Formatter/BambooExtended.pm',
    'ABSTRACT_FROM' => 'lib/TAP/Formatter/BambooExtended.pm',
    'PREREQ_PM'     => {
       'Test::XML'    => '0',
       'TAP::Harness' => '3.2',
       'Encode'       => '2.42',
       'Test::More'   => '0',
       'HTML::Parser' => '0',
       'XML::LibXML'  => '2',
       'File::Slurp'  => '0',
    },
    'INSTALLDIRS'   => (($] < 5.011) ? 'perl' : 'site'),

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

