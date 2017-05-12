#!/usr/bin/perl -I../lib -w
# Run this program from the command line with:
#     perl -I../lib -MRemote::Use=config,rsyncconfig prime3.pl  
use Math::Prime::XS qw{:all};

@all_primes   = primes(9);
print "@all_primes\n";

@range_primes = primes(4, 9);
print "@range_primes\n";
