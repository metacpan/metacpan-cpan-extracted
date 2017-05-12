#!perl -T

use strict;
use warnings;

use Test::More tests => 4 * 3 + 3;

use Scope::Context;

{
 my $flag;
 {
  {
   my $up = Scope::Context->up;
   $up->reap(sub { $flag = -1 });
   is $flag, undef, 'reap: not yet 1';
   $flag = 1;
  }
  is $flag, 1, 'reap: not yet 2';
  $flag = 2;
 }
 is $flag, -1, 'reap: done';
}

{
 our $x;
 {
  local $x = 1;
  {
   local $x = 2;
   my $up = Scope::Context->up(2);
   $up->localize('$x', -1);
   is $x, 2, 'localize: not yet 1';
   $x = 3;
  }
  is $x, 1, 'localize: not yet 2';
  $x = 4;
 }
 is $x, -1, 'localize: done';
}

{
 our %h;
 {
  local $h{x} = 1;
  {
   local $h{x} = 2;
   my $up = Scope::Context->up(2);
   $up->localize_elem('%h', 'x', -1);
   is $h{x}, 2, 'localize_elem: not yet 1';
   $h{x} = 3;
  }
  is $h{x}, 1, 'localize_elem: not yet 2';
  $h{x} = 4;
 }
 is $h{x}, -1, 'localize_elem: done';
}

{
 our %h = (x => 0);
 {
  local $h{x} = 1;
  {
   local $h{x} = 2;
   my $up = Scope::Context->up(2);
   $up->localize_delete('%h', 'x');
   is $h{x}, 2, 'localize_delete: not yet 1';
   $h{x} = 3;
  }
  is $h{x}, 1, 'localize_delete: not yet 2';
  $h{x} = 4;
 }
 ok !exists($h{x}), 'localize_delete: done';
}

{
 my @res = sub {
  sub {
   my $up = Scope::Context->sub(1);
   $up->unwind(1, 2, 3);
   fail 'unwind: not reached 1';
  }->();
  fail 'unwind: not reached 2';
  return qw<x y z t>;
 }->();
 is_deeply \@res, [ 1, 2, 3 ], 'unwind: done';
}

{
 my @res = do {
  sub {
   my $up = Scope::Context->up;
   $up->yield(4, 5, 6);
   fail 'yield: not reached 1';
  }->();
  fail 'yield: not reached 2';
  return qw<x y z t>;
 };
 is_deeply \@res, [ 4, 5, 6 ], 'yield: done';
}

{
 sub outer {
  inner(@_);
 }
 sub inner {
  my $up = Scope::Context->sub(1);
  my $name = $up->uplevel(
   sub { (caller 0)[$_[0]] } => 3
  );
  is $name, 'main::outer', 'uplevel: done';
 }
 outer();
}
