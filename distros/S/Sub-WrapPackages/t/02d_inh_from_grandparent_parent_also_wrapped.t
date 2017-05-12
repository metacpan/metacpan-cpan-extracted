#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;
use Data::Dumper;

my $pre; my $post;

use lib 't/lib'; use c;
use Sub::WrapPackages (
    packages       => [qw(b c)],
    wrap_inherited => 1,
    pre            => sub { $pre .= join(", ", @_); },
    post           => sub { $post .= join(', ', @_); }
);

my $r = c->a_scalar(94);

is($pre, 'c::a_scalar, c, 94',
  "when wrapping methods inherited from grandparent, pre is good");
is($post, 'c::a_scalar, in sub a_scalar',
  "when wrapping methods inherited from grandparent, post is good");
is($r, 'in sub a_scalar',
  "when wrapping methods inherited from grandparent, return value is good");

is(c->a_context_sensitive(), 'not redefined',
    'overridden grandparent method not redefined');
is(c->b_function(), 'not redefined',
    'overridden parent method not redefined');
