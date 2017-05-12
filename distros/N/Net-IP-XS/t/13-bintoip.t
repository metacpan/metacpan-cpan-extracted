#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 16;

use Net::IP::XS qw(ip_bintoip Error Errno);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

my $res = ip_bintoip('1' x 8, 4);
is($res, '0.0.0.255',
    'ip_bintoip 4');

$res = ip_bintoip('1' x 32, 4);
is($res, '255.255.255.255',
    'ip_bintoip 4');

$res = ip_bintoip('1', 4);
is($res, '0.0.0.1',
    'ip_bintoip 4');

$res = ip_bintoip('1' x 33, 4);
is($res, undef, 'ip_bintoip invalid');
is(Error(), 'Invalid IP length for binary IP '.('1' x 33),
    'Correct error message');
is(Errno(), 189, 'Correct error number');

$res = ip_bintoip('1', 6);
is($res, '0000:0000:0000:0000:0000:0000:0000:0001',
    'ip_bintoip 6');

$res = ip_bintoip('1' x 16, 6);
is($res, '0000:0000:0000:0000:0000:0000:0000:ffff',
    'ip_bintoip 6');

$res = ip_bintoip(('1' x 127).'0', 6);
is($res, 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe',
    'ip_bintoip 6');

$res = ip_bintoip('1' x 128, 6);
is($res, 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
    'ip_bintoip 6');

$res = ip_bintoip('1' x 129, 6);
is($res, undef, 'ip_bintoip invalid');
is(Error(), 'Invalid IP length for binary IP '.
                        ('1' x 129),  
   'Correct error message');
is(Errno(), 189, 'Correct error number');

$c->start();
$res = ip_bintoip(undef, 0);
$c->stop();
is($res, (join ':', ('0000') x 8), 
    'ip_bintoip returns zero address on undef and bad version');

$res = ip_bintoip('2020', 4);
is($res, '0.0.0.0', 
    'ip_bintoip returns zero address on non-bitstring (4)');
$res = ip_bintoip('2020', 6);
is($res, (join ':', ('0000') x 8), 
    'ip_bintoip returns zero address on non-bitstring (6)');

1;
