#!/usr/local/bin/perl
use inc::Module::Install;

name        ('RTx-DDMU');
author      ('Hsin-Chan Chien <hcchien@hcchien.org>');
abstract    ('add the new user interface for the RT with drop down menubar.');
license	    ('perl');
version_from('lib/RTx/DDMU.pm');
requires    ('HTML::CalendarMonthSimple');
WriteAll    ( sign => 1 );
