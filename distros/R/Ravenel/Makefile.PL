#!/usr/bin/perl

use strict;

use inc::Module::Install;

name          'Ravenel';
all_from      'lib/Ravenel.pm';
requires      'PPI'             => '1.208';
requires      'Module::Install' => 0;
license       'perl';
test_requires 'Test::More' => '0.47';
perl_version  '5.006';

WriteAll;
