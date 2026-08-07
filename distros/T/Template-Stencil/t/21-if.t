#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub r { Template::Stencil::_render(@_) }

# Truthiness.
is(r('{% if v %}T{% else %}F{% end %}', { v => 1 }),     'T', '1 true');
is(r('{% if v %}T{% else %}F{% end %}', { v => 0 }),     'F', '0 false');
is(r('{% if v %}T{% else %}F{% end %}', { v => '' }),    'F', "'' false");
is(r('{% if v %}T{% else %}F{% end %}', { v => '0' }),   'F', "'0' false");
is(r('{% if v %}T{% else %}F{% end %}', { v => undef }), 'F', 'undef false');
is(r('{% if v %}T{% else %}F{% end %}', {}),             'F', 'missing false');
is(r('{% if v %}T{% else %}F{% end %}', { v => '00' }),  'T', "'00' true (Perl)");

# The documented extension: empty aggregates are false.
is(r('{% if v %}T{% else %}F{% end %}', { v => [] }), 'F', 'empty aref false');
is(r('{% if v %}T{% else %}F{% end %}', { v => {} }), 'F', 'empty href false');
is(r('{% if v %}T{% else %}F{% end %}', { v => [0] }), 'T',
   'non-empty aref true');
is(r('{% if v %}T{% else %}F{% end %}', { v => { a => 1 } }), 'T',
   'non-empty href true');

# unless.
is(r('{% unless v %}T{% end %}', { v => 0 }), 'T', 'unless false body');
is(r('{% unless v %}T{% end %}', { v => 1 }), '', 'unless true skip');

# elsif chain.
for my $case ([1, 'one'], [2, 'two'], [9, 'many']) {
    is(r('{% if a == 1 %}one{% elsif a == 2 %}two{% else %}many{% end %}',
         { a => $case->[0] }), $case->[1], "elsif chain a=$case->[0]");
}

# Numeric vs string comparison semantics.
is(r(q<{% if a == b %}T{% else %}F{% end %}>, { a => '10', b => 10 }), 'T',
   "'10' == 10");
is(r(q<{% if a eq b %}T{% else %}F{% end %}>, { a => '10', b => '10.0' }),
   'F', "'10' eq '10.0' false");
is(r('{% if a < b %}T{% else %}F{% end %}',  { a => 9, b => 10 }), 'T',
   '9 < 10 numeric');
is(r('{% if a lt b %}T{% else %}F{% end %}', { a => 9, b => 10 }), 'F',
   "'9' lt '10' string false");
is(r('{% if a >= b %}T{% else %}F{% end %}', { a => 2, b => 2 }), 'T', '>=');
is(r('{% if a ne b %}T{% else %}F{% end %}', { a => 'x', b => 'y' }), 'T',
   'ne');
is(r(q[{% if name eq 'admin' %}T{% else %}F{% end %}],
     { name => 'admin' }), 'T', 'string literal comparison');
is(r('{% if n == 3.5 %}T{% else %}F{% end %}', { n => 3.5 }), 'T',
   'number literal comparison');

# Boolean operators short-circuit with Perl value semantics.
is(r('{% if a && b %}T{% else %}F{% end %}', { a => 1, b => 1 }), 'T',
   '&& both');
is(r('{% if a && b %}T{% else %}F{% end %}', { a => 1, b => 0 }), 'F',
   '&& rhs false');
is(r('{% if a || b %}T{% else %}F{% end %}', { a => 0, b => 1 }), 'T',
   '|| rhs');
is(r('{% if a or b %}T{% else %}F{% end %}', { a => 0, b => 0 }), 'F',
   'or both false');
is(r('{% if not a %}T{% else %}F{% end %}', { a => 0 }), 'T', 'not');
is(r('{% if !a %}T{% else %}F{% end %}',    { a => 1 }), 'F', 'bang');
is(r('{% if a || b && c %}T{% else %}F{% end %}',
     { a => 0, b => 1, c => 0 }), 'F', 'precedence a||(b&&c)');
is(r('{% if (a || b) && c %}T{% else %}F{% end %}',
     { a => 1, b => 0, c => 0 }), 'F', 'parens');

# defined().
is(r('{% if defined(v) %}D{% else %}U{% end %}', { v => 0 }),     'D',
   'defined 0');
is(r('{% if defined(v) %}D{% else %}U{% end %}', { v => undef }), 'U',
   'defined undef');
is(r('{% if defined(v) %}D{% else %}U{% end %}', {}),             'U',
   'defined missing');

# undef literal.
is(r('{% if a eq undef %}T{% else %}F{% end %}', { a => '' }), 'T',
   "'' eq undef (Perl stringy semantics)");

# Nesting.
is(r('{% if a %}{% if b %}AB{% else %}A{% end %}{% else %}N{% end %}',
     { a => 1, b => 0 }), 'A', 'nested if');

done_testing;
