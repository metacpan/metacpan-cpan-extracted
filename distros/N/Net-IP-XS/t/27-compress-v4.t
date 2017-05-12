#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 16;

use Net::IP::XS qw(ip_compress_v4_prefix);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

my $res;
my @res;

my @data = (
    [ '',                       '',     '' ],
    [ undef,                    undef,  '' ],
    [ 'abcd',                   'ef',   'abcd' ],
    [ '255.255.255.255.255',    'ef',   undef ],
    [ '...................',    'ef',   undef ],
    [ qw(127.0.0.1              -100),  undef ],
    [ qw(127.0.0.1              100),   undef ],
    [ qw(127.0.0.1              0       127) ],
    [ qw(127.0.0.1              1       127) ],
    [ qw(127.0.0.1              8       127) ],
    [ qw(127.0.0.1              9       127.0) ],
    [ qw(127.0.0.1              16      127.0) ],
    [ qw(127.0.0.1              24      127.0.0) ],
    [ qw(127.0.0.1              31      127.0.0.1) ],
    [ qw(127.0.0.1              32      127.0.0.1) ],
    [ qw(127.0.0.1/32           32      127.0.0.1/32) ], 
);

for (@data) {
    my ($addr, $length, $res_exp) = @{$_};
    $c->start();
    my $res = ip_compress_v4_prefix($addr, $length);
    $c->stop();
    for ($addr, $length) {
        defined $_ or $_ = 'undef';
    }
    is($res, $res_exp, "$addr - $length");
}

1;
