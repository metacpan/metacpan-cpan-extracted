#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

my $pre;
use Sub::WrapPackages (
    packages => [qw(a)],
    pre => sub { $pre .= join(", ", @_); },
);
use lib 't/lib';
use a;

my $r = a::a_scalar(1..3);

is($pre, 'a::a_scalar, 1, 2, 3', "can 'use lib' late too");
