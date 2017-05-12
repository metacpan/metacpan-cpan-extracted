#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 27;

use Net::IP::XS qw(ip_bincomp Error Errno);

my $res = ip_bincomp('11', 'gte', '11');
is(Error(), 'Invalid Operator gte', 
    'Correct error message');
is(Errno(), 131, 'Correct errno');

$res = ip_bincomp('1', 'ge', '11');
is(Error(), 'IP addresses of different length', 
    'Correct error message');
is(Errno(), 130, 'Correct errno');

my @data = (
    [ qw(1 le 0 0) ],
    [ qw(0 le 0 1) ],
    [ qw(0 le 1 1) ],
    [ qw(1 le 1 1) ],
    [ qw(1 ge 0 1) ],
    [ qw(0 ge 0 1) ],
    [ qw(0 ge 1 0) ],
    [ qw(1 ge 1 1) ],
    [ qw(1 lt 0 0) ],
    [ qw(0 lt 0 0) ],
    [ qw(0 lt 1 1) ],
    [ qw(1 lt 1 0) ],
    [ qw(1 gt 0 1) ],
    [ qw(0 gt 0 0) ],
    [ qw(0 gt 1 0) ],
    [ qw(1 gt 1 0) ],
    [ qw(1001 ge 1010 0) ],
    [ qw(01 lt 10 1) ],
    [ qw(10 gt 01 1) ],
    [ '0' x 32, 'ge', '1', undef ],
    [ '1' x 128, 'le', '1' x 128, 1 ],
    [ ('1' x 127).'0', 'lt', '1' x 128, 1 ],
    [ ('1' x 511).'0', 'lt', '1' x 512, 1 ],
);

for (@data) {
    my ($first, $op, $second, $res_exp) = @{$_};
    my $res = ip_bincomp($first, $op, $second);
    is($res, $res_exp, "$first $op $second");
}

1;
