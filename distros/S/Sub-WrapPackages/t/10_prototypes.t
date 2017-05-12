#!/usr/bin/perl -w

use strict;

my $pre;
my $post;

use Test::More tests => 4;

sub mypush(\@@) { @{$_[0]} = (@{$_[0]}, @_[1..$#_]); }

BEGIN {
  my @array = ();
  mypush @array, (1,2);
  is_deeply(\@array, [1, 2], "without wrapping, prototyped function works");
  ok(!$pre, "... and yes, it really wasn't wrapped");
}

use Sub::WrapPackages (
  subs => [qw(main::mypush)],
  pre => sub { $pre  = 'pre' }
);

my @array = ();
mypush @array, (1,2);
is_deeply(\@array, [1, 2], "with wrapping, prototyped function still works");
ok($pre eq 'pre', "... and yes, it really was wrapped");
