#!/usr/bin/perl
use strict;
use warnings;
use Sort::Radix;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sort-Radix.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 2;
use Test::More qw(no_plan);
use_ok('Sort::Radix', qw(radix_sort));
#BEGIN { use_ok('Sort::Radix') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %tests = (Radix => ['flow', 'loop', 'pool', 'Wolf', 'root', 'tour']);

can_ok('Sort::Radix', qw(radix_sort));
require_ok('Sort::Radix');

my @array = qw(flow loop pool Wolf root sort tour);
   radix_sort(\@array);
   print "@array\n";
