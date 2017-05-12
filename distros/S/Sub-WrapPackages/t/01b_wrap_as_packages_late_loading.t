#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

my $pre; my $post;
use lib 't/lib';
use Sub::WrapPackages (
    packages => [qw(a)],
    pre => sub { $pre .= join(", ", @_); },
    post => sub { $post .= join(", ", @_); }
);
use a;

my $r = a::a_scalar(1..3);

is($pre, 'a::a_scalar, 1, 2, 3',
    'package pre-wrapper works');
is($post, 'a::a_scalar, in sub a_scalar',
    'package post-wrapper works');
is($r, 'in sub a_scalar',
    'package-wrapped sub returns correctly');
