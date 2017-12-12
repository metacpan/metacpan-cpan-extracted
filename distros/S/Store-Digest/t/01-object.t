#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use URI::ni;
use DateTime;

plan tests => 2;

use_ok('Store::Digest::Object');

#use Store::Digest::Object;

my $empty = URI::ni->compute('', 'sha-256');
diag($empty);

my $obj = Store::Digest::Object->new(
    digests => { 'sha-256' => $empty },
    type    => 'application/x-empty',
    size    => 0,
    ctime   => DateTime->now,
);

isa_ok($obj, 'Store::Digest::Object');
