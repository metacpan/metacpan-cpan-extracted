#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use experimental 'signatures';

use Syntax::Keyword::MultiSub;

{
   multi sub f ()       { return "<nullary>" }
   multi sub f ($x)     { return "<unary($x)>" }
   multi sub f ($x, $y) { return "<binary($x, $y)>" }

   is( f(),         "<nullary>",      'f() zero args' );
   is( f("a"),      "<unary(a)>",     'f() one arg' );
   is( f("b", "c"), "<binary(b, c)>", 'f() two args' );

   like( dies { f("too", "many", "args") },
      qr/^Unable to find a function body for a call to &main::f having 3 arguments at /,
      'f() complains with too many args' );
}

{
   multi sub g () { return "zero"; }
   multi sub g ($x, $y = 123) { return "one-or-two($x,$y)"; }

   is( g("x"),      "one-or-two(x,123)", 'g() one arg' );
   is( g("x", "y"), "one-or-two(x,y)",   'g() two args' );
}

{
   multi sub h ($one)  { return "unary($one)" }
   multi sub h (@rest) { return "slurpy(@rest)" }

   is( h(1),     "unary(1)",      'h() one arg' );
   is( h(2,3,4), "slurpy(2 3 4)", 'h() three args' );
   is( h(),      "slurpy()",      'h() zero args' );
}

{
   no Syntax::Keyword::MultiSub;

   sub multi { return "normal function" }

   is( multi, "normal function", 'multi() parses as a normal function call' );
}

done_testing;
