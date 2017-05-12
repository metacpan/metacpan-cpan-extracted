#!/usr/bin/perl

use lib 'lib', '../lib';

use POSIX::strftime::GNU;
use POSIX qw( strftime locale_h );

setlocale(LC_TIME, 'C');

print strftime('%a, %d %b %Y %T %z', localtime), "\n";
