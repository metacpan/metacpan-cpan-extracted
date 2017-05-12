#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 33;

use Net::IP::XS qw(ip_is_overlap
                   ip_iptobin
                   Error
                   Errno
                   $IP_NO_OVERLAP
                   $IP_PARTIAL_OVERLAP
                   $IP_A_IN_B_OVERLAP
                   $IP_B_IN_A_OVERLAP
                   $IP_IDENTICAL);

my $c = 1;
for my $det ([qw(1 12 123 1234)],
             [qw(1  1 123 1234)],
             [qw(1  1  12   12)]) {
    my ($b1, $e1, $b2, $e2) = @{$det}; 
    my $res = ip_is_overlap($b1, $e1, $b2, $e2);
    is($res, undef, "Got no result on strings of different lengths ($c)");
    is(Error(), 'IP addresses of different length',
        'Got correct error');
    is(Errno(), 130, 'Got correct errno');
}

my $res = ip_is_overlap('1', '0', '0', '0');
is($res, undef, 'Got no result on bad range (1)');
is(Error(), 'Invalid range 1 - 0',
    'Got correct error');
is(Errno(), 140, 'Got correct errno');

$res = ip_is_overlap('0', '0', '1', '0');
is($res, undef, 'Got no result on bad range (2)');
is(Error(), 'Invalid range 1 - 0',
    'Got correct error');
is(Errno(), 140, 'Got correct errno');

my @data = (
    [ qw(127.0.0.1    127.0.0.255
         128.0.0.0    128.0.0.255
         4),          $IP_NO_OVERLAP ],
    [ qw(127.0.0.1    128.0.0.0
         128.0.0.0    128.0.0.255
         4),          $IP_PARTIAL_OVERLAP ],
    [ qw(127.0.0.1    128.0.0.0
         127.0.0.0    127.255.255.255
         4),          $IP_PARTIAL_OVERLAP ],
    [ qw(127.0.0.1    129.0.0.0
         128.0.0.0    129.0.0.0
         4),          $IP_B_IN_A_OVERLAP ],
    [ qw(128.0.0.1    129.0.0.0
         127.0.0.0    129.0.0.0
         4),          $IP_A_IN_B_OVERLAP ],
    [ qw(127.0.0.1    127.0.0.255
         126.0.0.0    128.0.0.255
         4),          $IP_A_IN_B_OVERLAP ],
    [ qw(0.0.0.0      255.255.255.255
         126.0.0.0    128.0.0.255
         4),          $IP_B_IN_A_OVERLAP ],
    [ qw(0.0.0.0      255.255.255.255
         0.0.0.0      255.255.255.255
         4),          $IP_IDENTICAL ],
    [ (join ':', ('0000') x 8), (join ':', ('1111') x 8),
      (join ':', ('2222') x 8), (join ':', ('3333') x 8),
      6,              $IP_NO_OVERLAP ],
    [ (join ':', ('0000') x 8), (join ':', ('1111') x 8),
      (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      6,              $IP_PARTIAL_OVERLAP ],
    [ (join ':', ('0000') x 8), (join ':', ('5555') x 8),
      (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      6,              $IP_B_IN_A_OVERLAP ],
    [ (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      (join ':', ('0000') x 8), (join ':', ('1111') x 8),
      6,              $IP_PARTIAL_OVERLAP ],
    [ (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      (join ':', ('1111') x 8), (join ':', ('5555') x 8),
      6,              $IP_A_IN_B_OVERLAP ],
    [ (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      (join ':', ('0000') x 8), (join ':', ('3333') x 8),
      6,              $IP_A_IN_B_OVERLAP ],
    [ (join ':', ('0000') x 8), (join ':', ('3333') x 8),
      (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      6,              $IP_B_IN_A_OVERLAP ],
    [ (join ':', ('0000') x 8), (join ':', ('3333') x 8),
      (join ':', ('1111') x 8), (join ':', ('4444') x 8),
      6,              $IP_PARTIAL_OVERLAP ],
    [ (join ':', ('1111') x 8), (join ':', ('3333') x 8),
      (join ':', ('0000') x 8), (join ':', ('4444') x 8),
      6,              $IP_A_IN_B_OVERLAP ],
    [ (join ':', ('0000') x 8), (join ':', ('ffff') x 8),
      (join ':', ('0000') x 8), (join ':', ('ffff') x 8),
      6,              $IP_IDENTICAL ],
);

for (@data) {
    my ($b1, $e1, $b2, $e2, $version, $res_exp) = @{$_};
    my $res = ip_is_overlap(ip_iptobin($b1, $version),
                            ip_iptobin($e1, $version),
                            ip_iptobin($b2, $version),
                            ip_iptobin($e2, $version));
    is($res, $res_exp, "$b1 - $e1, $b2 - $e2");
}

1;
