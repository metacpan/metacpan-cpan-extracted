#!/usr/bin/perl -w

use strict;

my $pre;
my $post;

use Test::More tests => 10;

use lib 't/lib'; use a;
use Sub::WrapPackages (
    subs => [qw(a::a_scalar a::a_list a::a_context_sensitive)],
    pre => sub { $pre .= join(", ", @_); },
    post => sub { $post .= join(", ", @_); }
);

my $r = a::a_scalar(1..3);

is($pre, 'a::a_scalar, 1, 2, 3',
    'pre-wrapper works in scalar context');
is($post, 'a::a_scalar, in sub a_scalar',
    'post-wrapper works in scalar context');
is($r, 'in sub a_scalar',
    'return scalar in scalar context');

$pre = $post = '';
my @r = a::a_list(4,6,8);

is($pre, 'a::a_list, 4, 6, 8',
    'pre-wrapper works in list context');
is($post, 'a::a_list, in, sub, a_list',
    'post-wrapper works in list context');
is(join(', ', @r), 'in, sub, a_list',
    'return list in list context');

a::a_context_sensitive();
ok($main::voidcontext, 'wantarray() undef in void context');
is_deeply(my $foo = a::a_context_sensitive(), [qw(in sub a_context_sensitive)],
    'wantarray() false in scalar context');
is_deeply([my @foo = a::a_context_sensitive()], [qw(in sub a_context_sensitive)],
    'wantarray() true in list context');

Sub::WrapPackages::wrapsubs(
    subs => [qw(a::a_scalar a::a_list a::a_context_sensitive)],
    pre => sub { $pre .= join(", ", @_); },
    post => sub { $post .= join(", ", @_); }
);
$pre = '';
$r = a::a_scalar(1..3);
is($pre, 'a::a_scalar, 1, 2, 3', "subs can't be re-wrapped");
