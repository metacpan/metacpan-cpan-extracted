#!/usr/bin/perl

use strict;
use warnings;

use Time::Local;
use POSIX::strftime::Compiler;

my $fmt = shift @ARGV || '%z';
my @t = @ARGV ? localtime timelocal(@ARGV) : localtime;

print POSIX::strftime::Compiler::strftime($fmt,@t);

