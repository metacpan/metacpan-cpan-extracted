#!/usr/local/bin/perl5.8.8

use Slay::Makefile::Gress qw(do_tests);
Test::More->builder->no_ending(1);
do_tests("Dir.smak", @ARGV);

