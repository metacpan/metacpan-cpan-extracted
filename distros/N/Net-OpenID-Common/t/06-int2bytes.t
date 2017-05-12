#!/usr/bin/perl
    
use strict;
use Test::More tests => 2048;
use Net::OpenID::Common;
use Math::BigInt;
    
for my $num (1..2048) {
    my $bi = Math::BigInt->new("2")->bpow($num);
    my $bstr = $bi->bstr;

    my $bytes = OpenID::util::int2bytes($bstr);
    my $bstr2 = OpenID::util::bytes2int($bytes);
    is($bstr,$bstr2);
}

