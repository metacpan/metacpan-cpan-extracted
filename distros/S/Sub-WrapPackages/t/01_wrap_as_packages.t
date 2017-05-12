#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use lib 't/lib'; use a;
my $pre; my $post;
use Sub::WrapPackages (
    packages => [qw(a)],
    pre => sub { $pre .= join(", ", @_); },
    post => sub { $post .= join(", ", @_); }
);

my $r = a::a_scalar(1..3);

is($pre, 'a::a_scalar, 1, 2, 3',
    'package pre-wrapper works');
is($post, 'a::a_scalar, in sub a_scalar',
    'package post-wrapper works');
is($r, 'in sub a_scalar',
    'package-wrapped sub returns correctly');

Sub::WrapPackages::wrapsubs(
    packages => [qw(a)],
    pre => sub { $pre .= join(", ", @_); },
    post => sub { $post .= join(", ", @_); }
);
$pre = '';
$r = a::a_scalar(1..3);
is($pre, 'a::a_scalar, 1, 2, 3', "subs can't be re-wrapped via a package");
