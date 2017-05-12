#!/usr/local/bin/perl5.8.8

use Slay::Makefile::Gress qw(do_tests);
do_tests("Dir.smak", @ARGV, { opts=> { strict=>0 } });
