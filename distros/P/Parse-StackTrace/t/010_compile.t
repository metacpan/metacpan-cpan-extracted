#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Support qw(all_modules);

my @modules = all_modules('lib');
plan tests => scalar(@modules);
use_ok($_) foreach @modules;
