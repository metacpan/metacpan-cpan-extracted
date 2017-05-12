#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use Data::Dumper;

my $pre; my $post;

use lib 't/lib'; use b;
use Sub::WrapPackages (
    packages       => [qw(b)],
    wrap_inherited => 1,
    pre            => sub { $pre .= join(", ", @_); },
    post           => sub { $post .= join(', ', @_); }
);

my $r = b->b_function(94);

is($pre, 'b::b_function, b, 94',
  "when wrapping inherited methods, normal methods' pre-wrappers are OK");
is($post, 'b::b_function, i like pie',
  "when wrapping inherited methods, normal methods' post-wrappers are OK");
is($r, 'i like pie',
  "when wrapping inherited methods, normal methods' return the right value");

$pre = $post = '';
my @r = b->a_list(4,6,8);

is($pre, 'b::a_list, b, 4, 6, 8',
  "when wrapping inherited methods, pre-wrapper is OK");
is($post, 'b::a_list, in, sub, a_list',
  "when wrapping inherited methods, post-wrapper is OK");
is_deeply(\@r, [qw(in sub a_list)],
  "wrapped inherited method returns the right value");

$pre = $post = '';
@r = a->a_list(4,6,8);
ok($pre eq $post && $post eq '',
  "calling the superclass method directly avoids wrapping shenanigans");
is_deeply(\@r, [qw(in sub a_list)],
  "non-wrapped super-class method returns the right value");
