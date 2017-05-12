#!/usr/bin/perl -I../lib -w
use Remote::Use config => 'rsyncconfigtonga';
require Math::Prime::XS;
Math::Prime::XS->import(':all');

 @all_primes   = primes(9);
 print "@all_primes\n";

 @range_primes = primes(4, 9);
 print "@range_primes\n";

