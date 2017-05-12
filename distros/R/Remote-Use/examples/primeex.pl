#!/usr/bin/perl -I../lib -w
use Remote::Use 
    host => 'orion:',
    prefix => '/tmp/perl5lib/',
    command => 'rsync -i -vaue ssh',
    ppmdf => '/tmp/perl5lib/.orion.installed.modules',
;
use Math::Prime::XS qw{:all};

@all_primes   = primes(9);
print "@all_primes\n";

@range_primes = primes(4, 9);
print "@range_primes\n";
