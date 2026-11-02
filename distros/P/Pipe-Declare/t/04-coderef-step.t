#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 3 / coderef-expression step: callee is a coderef expression
# (\&name, sub { ... }, $cv); the topic is the sole argument.

sub double { $_[0] * 2 }
sub inc    { $_[0] + 1 }

# --- \&name ---------------------------------------------------------------

is( (pipe { 7 |> \&double }), 14, '\&name calls the named sub with topic' );
is( (pipe { 7 |> \&double |> \&inc }), 15, 'chained \&name steps' );

# A mix of bareword and \&name forms must be equivalent.
is( (pipe { 3 |> double |> \&inc }),  (pipe { 3 |> \&double |> inc }),
    'bareword and \&name forms are interchangeable' );

# --- sub { ... } anonymous-sub step --------------------------------------

is( (pipe { 5 |> sub { $_[0] * 3 } }), 15, 'sub { ... } step receives topic in @_' );

is( (pipe { 2 |> sub { $_[0] + 1 } |> sub { $_[0] * $_[0] } }),
    9,
    'two sub { ... } steps' );

# Mixed with bareword:
is( (pipe { 4 |> inc |> sub { $_[0] * 10 } |> double }),
    100,
    'sub { ... } interleaves with bareword steps' );

# --- $cv  (a scalar holding a coderef) -----------------------------------

my $doubler = \&double;
is( (pipe { 6 |> $doubler }), 12, '$cv step calls the coderef with topic' );

# Anonymous closure in a scalar.
my $shift = sub { $_[0] - 10 };
is( (pipe { 100 |> $shift |> $doubler }), 180, 'closure $cv chained with \&name' );

# --- the head can itself be a coderef call (via parens) ------------------

is( (pipe { ( $doubler->(3) ) |> inc }), 7, 'coderef head via (EXPR)' );

# --- a qualified \&Pkg::name --------------------------------------------

package Util;
sub neg { -$_[0] }
package main;

is( (pipe { 5 |> \&Util::neg }), -5, '\&Pkg::name works' );

done_testing;
