#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

my $v=1;
my %h=(a=>\$v);
${$h{a}}=2;
say $v;
