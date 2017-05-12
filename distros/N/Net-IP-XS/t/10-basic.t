#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 11;

use Net::IP::XS qw(
    $IP_NO_OVERLAP      
    $IP_PARTIAL_OVERLAP 
    $IP_A_IN_B_OVERLAP  
    $IP_B_IN_A_OVERLAP  
    $IP_IDENTICAL
);

use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

$Net::IP::XS::ERROR = 'asdf';
is($Net::IP::XS::ERROR, 'asdf', 'Error stored correctly');

$Net::IP::XS::ERRNO = 1234;
is($Net::IP::XS::ERRNO, 1234, 'Errno stored correctly');

$c->start();
$Net::IP::XS::ERROR = undef;
$Net::IP::XS::ERRNO = undef;
$c->stop();
is($Net::IP::XS::ERROR, '', 'Error is string when set to undef');
is($Net::IP::XS::ERRNO, 0,  'Errno is number when set to undef');

$Net::IP::XS::ERROR = 'e' x 1024;
is($Net::IP::XS::ERROR, 'e' x 511,
    'Error messaged truncated properly');

$c->start();
$Net::IP::XS::ERRNO = 'not a number';
$c->stop();
is($Net::IP::XS::ERRNO, 0, 'Errno is zero after setting as string');

is($IP_NO_OVERLAP,      0, 'IP_NO_OVERLAP has correct value');
is($IP_PARTIAL_OVERLAP, 1, 'IP_PARTIAL_OVERLAP has correct value');
is($IP_A_IN_B_OVERLAP, -1, 'IP_A_IN_B_OVERLAP has correct value');
is($IP_B_IN_A_OVERLAP, -2, 'IP_B_IN_A_OVERLAP has correct value');
is($IP_IDENTICAL,      -3, 'IP_IDENTICAL has correct value');

1;
