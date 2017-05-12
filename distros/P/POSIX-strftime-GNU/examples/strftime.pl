#!/usr/bin/perl

use lib 'lib', '../lib';

use POSIX::strftime::GNU;
use POSIX qw( strftime );

my @t = defined $ARGV[1] ? localtime $ARGV[1] : localtime;

print strftime($ARGV[0], @t), "\n";
