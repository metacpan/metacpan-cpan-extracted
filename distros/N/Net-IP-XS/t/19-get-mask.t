#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 12;

use Net::IP::XS qw(ip_get_mask Error Errno);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

$c->start();
my $res = ip_get_mask(undef, 0);
$c->stop();
is($res, undef, 'Got undef on no version');
is(Error(), "Cannot determine IP version",
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

my @data = (
    [ -10,  4,  '0' x 32 ],
    [ 0,    4,  '0' x 32 ],
    [ 1,    4,  '1'.('0' x 31) ],
    [ 32,   4,  '1' x 32 ],
    [ 50,   4,  '1' x 32 ],
    [ 16,   4,  ('1' x 16).('0' x 16) ],
    [ 0,    6,  ('0' x 128) ],
    [ 32,   6,  ('1' x 32).('0' x 96) ],
    [ 150,  6,  ('1' x 128) ],
);

for (@data) {
    my ($length, $version, $res_exp) = @{$_};
    my $res = ip_get_mask($length, $version);
    is($res, $res_exp, "$length - $version");
}

1;
