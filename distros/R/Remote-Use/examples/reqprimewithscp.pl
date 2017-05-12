#!/usr/bin/perl -I../lib -Ilib/ -w
use strict;

use Remote::Use config => 'rsyncconfigwithscp', package => 'rsyncconfigwithscp';
use Math::Prime::XS qw{:all};

my @p = primes(9);

print "@p\n";
