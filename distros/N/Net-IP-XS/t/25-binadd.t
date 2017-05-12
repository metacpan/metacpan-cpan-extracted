#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 15;

use Net::IP::XS qw(ip_binadd Error Errno);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

my $res = ip_binadd('0', '01');
is($res, undef, 'Got no result on different lengths');
is(Error(), 'IP addresses of different length',
    'Got correct error');
is(Errno(), 130, 'Got correct errno');

my @data = (
    [ undef, undef, '' ],
    [ '', '', '' ],
    [ 'abcd', 'edfh', '1110' ],
    [ qw(0 0 0) ],
    [ qw(1 1 0) ],
    [ qw(1010 0101 1111) ],
    [ qw(11111111 00000001 00000000) ],
    [ '0000001110111011101110111011101110111011101110111011101110111011'.
      '1011101110111011101110111011101110111011101110111011101110111011',
      '0000001110111011101110111011101110111011101110111011101110111011'.
      '1011101110111011101110111011101110111011101110111011101110111011',
      '0000011101110111011101110111011101110111011101110111011101110111'.
      '0111011101110111011101110111011101110111011101110111011101110110', ],
    [ '1' x 128, '1' x 128, ('1' x 127).'0' ],
    [ '1' x 129, '1' x 128, undef ],
    [ '1' x 129, '1' x 129, undef ],
    [ '1' x 1024, '1' x 1024, undef ],
);
 
for (@data) {
    my ($first, $second, $res_exp) = @{$_};
    if (not defined $first or not defined $second) {
        $c->start();
    }
    my $res = ip_binadd($first, $second);
    if (not defined $first or not defined $second) {
        $c->stop();
    }
    for ($first, $second) {
        defined $_ or $_ = 'undef';
    }
    is($res, $res_exp, "$first + $second");
}

1;
