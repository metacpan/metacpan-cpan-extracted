#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 12;

use Net::IP::XS qw(ip_splitprefix);

my @data = (
    [ '' => undef ],
    [ '/' => undef ],
    [ '1/' => undef ],
    [ '1/abcd' => undef ],
    [ '1/-1' => undef ],
    [ '100' => undef ],
    [ '127/32' => [ '127', '32' ] ],
    [ '127.0.0.1/32' => [ '127.0.0.1', '32' ] ],
    [ (join ':', ('0000') x 8).'/128' => 
        [ (join ':', ('0000') x 8), 128 ] ],
    [ ('1' x 256).'/500' => [] ],
    [ (join ':', ('255.255.255.255') x 4).'/128' => 
        [ (join ':', ('255.255.255.255') x 4), 128 ] ],
    [ (join ':', ('255.255.255.255') x 4).'a/128' => [] ],
);

for (@data) {
    my ($input, $res_exp) = @{$_};
    my @res = ip_splitprefix($input);
    if (ref $res_exp) {
        is_deeply(\@res, $res_exp, "Split prefix: $input");
    } else {
        is($res[0], $res_exp, "Split prefix: $input");
    }
}

1;
