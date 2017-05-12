#!perl -T

use strict;
use warnings;

use Test::More tests => 14;

use Scope::Context;

use Scope::Upper qw<HERE>;

# Constructor

{
 my $here = Scope::Context->new;
 is $here->cxt, HERE, 'default context';
}

{
 my $cxt = HERE;
 {
  my $here = Scope::Context->new($cxt);
  is $here->cxt, $cxt, 'forced context';
 }
}

# up

{
 my $cxt = HERE;
 {
  my $here = Scope::Context->new;
  my $up = $here->up;
  is $up->cxt, $cxt, 'up(undef)';
 }
}

{
 my $cxt = HERE;
 {
  my $here = Scope::Context->new;
  my $up1 = $here->up(1);
  is $up1->cxt, $cxt, 'up(1)';
 }
}

{
 my $cxt = HERE;
 {
  {
   my $up2 = Scope::Context->up(2);
   is $up2->cxt, $cxt, 'up(2)';
  }
 }
}

# sub

{
 sub {
  my $cxt = HERE;
  {
   my $sub = Scope::Context->new->sub;
   is $sub->cxt, $cxt, 'sub(undef)';
  }
 }->();
}

{
 sub {
  my $cxt = HERE;
  {
   my $sub = Scope::Context->new->sub(0);
   is $sub->cxt, $cxt, 'sub(0)';
  }
 }->();
}

{
 sub {
  my $cxt = HERE;
  sub {
   my $sub = Scope::Context->sub(1);
   is $sub->cxt, $cxt, 'sub(1)';
  }->();
 }->();
}

# eval

{
 local $@;
 eval {
  my $cxt = HERE;
  {
   my $eval = Scope::Context->new->eval;
   is $eval->cxt, $cxt, 'eval(undef)';
  }
 };
 die $@ if $@;
}

{
 local $@;
 eval {
  my $cxt = HERE;
  {
   my $eval = Scope::Context->new->eval(0);
   is $eval->cxt, $cxt, 'eval(0)';
  }
 };
 die $@ if $@;
}

{
 local $@;
 eval {
  my $cxt = HERE;
  eval {
   my $eval = Scope::Context->eval(1);
   is $eval->cxt, $cxt, 'eval(1)';
  };
  die $@ if $@;
 };
 die $@ if $@;
}

# want

{
 my $want;
 {
  local $@;
  my @res = eval {
   $want = Scope::Context->up->want;
  };
  die $@ if $@;
 };
 is $want, undef, 'want: void context';
}

{
 local $@;
 my $want;
 my $scalar = eval {
  my @res = do {
   $want = Scope::Context->eval->want;
  };
  'XXX';
 };
 die $@ if $@;
 is $want, !1, 'scalar context';
}

{
 my $want;
 my @list = sub {
  sub {
   $want = Scope::Context->sub->up->want;
  }->();
  'YYY';
 }->();
 is $want, 1, 'want: list context';
}
