#!/usr/bin/perl

use lib 'lib', '../lib';

use POSIX::strftime::GNU;
use POSIX qw( strftime locale_h );

setlocale(LC_TIME, 'C');

print strftime('%A, %d-%b-%y %T %Z', localtime), "\n";
