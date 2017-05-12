#!/usr/bin/perl
use strict;
use inc::Module::Install;

name       'Parse-Binary';
all_from   'lib/Parse/Binary.pm';
recommends 'Scalar::Util';

sign; WriteAll;
