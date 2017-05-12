#!/usr/bin/env perl

use inc::Module::Install;

name	    ('PAR-Filter-Squish');
author	    ('Steffen Mueller (smueller@cpan.org)');
abstract    ('PAR filter for reducing code size');
version_from('lib/PAR/Filter/Squish.pm');

requires    'Perl::Squish' => '0.02';
requires    'PAR'          => '0.94';

license	    ('perl');

&WriteAll   ( );

