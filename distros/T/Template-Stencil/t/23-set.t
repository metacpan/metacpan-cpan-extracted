#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# Literals, paths, expressions.
is(r(q[{% set x = 'lit' %}{% x %}], {}), 'lit', 'string literal set');
is(r('{% set x = 42 %}{% x %}', {}), '42', 'number literal set');
is(r('{% set x = a.b %}{% x %}', { a => { b => 'v' } }), 'v', 'path set');
is(r('{% set x = a || b %}{% x %}', { a => 0, b => 'fall' }), 'fall',
   'set with || takes deciding operand');
is(r('{% set x = a && b %}{% x %}', { a => 0, b => 'nope' }), '0',
   'set with && takes deciding operand');
is(r('{% set x = a == 1 %}[{% x %}]', { a => 1 }), '[1]',
   'boolean result true');
is(r('{% set x = undef %}[{% x %}]', {}), '[]', 'set undef');

# Rebinding: newest wins.
is(r('{% set x = 1 %}{% set x = 2 %}{% x %}', {}), '2', 'rebind');

# Set shadows data without mutating it.
{
    my $data = { x => 'data' };
    is(r('{% set x = "mine" %}{% x %}', $data), 'mine', 'set shadows data');
    is($data->{x}, 'data', 'data untouched');
}

# Block scoping: a set inside if/for dies with the block.
is(r('{% if a %}{% set x = "in" %}{% x %}{% end %}|{% x %}',
     { a => 1, x => 'out' }), 'in|out', 'if-block set expires');
is(r('{% for i in l %}{% set x = i %}{% x %}{% end %}|{% x %}',
     { l => [qw(a b)], x => 'out' }), 'ab|out', 'for-block set expires');

# Fresh per iteration: a bind from the previous pass is gone before the
# next one starts (print-before-set would leak 'F' into pass 2 if the
# per-iteration pop were missing).
is(r('{% for i in l %}[{% m %}{% set m = "F" %}]{% end %}',
     { l => [1, 2] }), '[][]', 'set fresh each iteration');

# And a set inside an if pops at the if's end, not the for's.
is(r('{% for i in l %}[{% if 1 %}{% set m = "F" %}{% m %}{% end %}{% m %}]{% end %}',
     { l => [1] }), '[F]', 'if-scoped set inside loop');

# Only the executed branch's set applies.
is(r('{% if a %}{% set x = "then" %}{% else %}{% set x = "else" %}{% end %}ok',
     { a => 0 }), 'ok', 'branch sets pop cleanly');

# Top-level set persists to end of template.
is(r('{% set x = 1 %}...{% x %}', {}), '...1', 'top-level set persists');

# Loop capture - the draft-test pattern.
is(r('{% for o in l %}{% set ol = loop %}{% for i in o %}{% ol.index %}{% ol.first %};{% end %}{% end %}',
     { l => [ ['a'], ['b'] ] }), '01;1;',
   'captured loop snapshot fields');

# Captured snapshot is frozen at capture time.
is(r('{% for i in l %}{% if loop.first %}{% set c = loop %}{% end %}{% end %}',
     { l => [1, 2, 3] }), '', 'capture without use is fine');

# set name reserved-word guard is compile-time (covered in t/14); a set
# of a loop var shadows just the variable.
is(r('{% for i in l %}{% set i = "X" %}{% i %}{% end %}', { l => [1, 2] }),
   'XX', 'set shadows loop var per iteration');

done_testing;
