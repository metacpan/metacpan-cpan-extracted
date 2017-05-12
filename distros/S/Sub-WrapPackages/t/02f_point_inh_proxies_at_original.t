#!/usr/bin/perl -w
# What if b inherits from a, a::foo is wrapped, and then
#   b::* are wrapped with wrap_inherited?

use strict;
use Test::More tests => 4;
use Data::Dumper;

my $pre; my $post;

use lib 't/lib'; use a;
# first wrap everything in a ...
use Sub::WrapPackages (
    packages       => [qw(a)],
    wrap_inherited => 1,
    pre            => sub { $pre++ },
    post           => sub { $post++ },
);

a->a_list(1,2,3);
ok($pre == $post && $post == 1, "pre and post are working");

# now load b and wrap everything in it, including inherited methods
eval 'use b';
Sub::WrapPackages::wrapsubs (
    packages => [qw(b)],
    wrap_inherited => 1,
    pre            => sub { $pre++ },
    post           => sub { $post++ },
);

$pre = $post = 0;
b->b_function();
ok($pre == $post && $post == 1, "pre and post work in the child for a non-inherited method");
$pre = $post = 0;
is_deeply([b->a_list()], [qw(in sub a_list)], "inherited method returns OK");
ok($pre == $post && $pre == 1, "and pre/post only get run once");
