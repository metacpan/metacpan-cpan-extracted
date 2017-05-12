#!/usr/bin/perl -I../lib -w
require Remote::Use;
Remote::Use->import(config => 'tutu/wgetconfigpm.pm');
require Math::Prime::XS;
Math::Prime::XS->import(qw{:all});

@all_primes   = primes(9);
print "@all_primes\n";

@range_primes = primes(4, 9);
print "@range_primes\n";
