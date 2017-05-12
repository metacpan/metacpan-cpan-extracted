#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use Scope::Context;

{
 my $sc = Scope::Context->new;
 {
  my $block = Scope::Context->new;
  my $up = $block->up;
  ok $up    == $sc, '$up == $sc';
  ok $block != $sc, '$block != $sc';
 }
}

{
 my @scs;
 for (1, 2) {
  push @scs, Scope::Context->new;
 }
 cmp_ok $scs[0], '!=', $scs[1], 'different iterations, different contextes';
}

{
 my $here = Scope::Context->new;
 my $dummy = bless [], 'Scope::Context::Test::DummyClass';
 for my $rhs ($here->cxt, $dummy) {
  local $@;
  eval { my $res = $here == $rhs };
  my $line = __LINE__-1;
  like $@, qr/^Cannot compare a Scope::Context object with something else at \Q$0\E line $line/, "Scope::Context == overload does not compare with $rhs";
 }
}
