#!/usr/bin/env perl

use strict;
use Rubyish;

use Test::More;

plan tests => 5;

{
    my $s = String("fnord");
    my $t = $s->gsub(qr/nor/, "oo");

    is $t, "food";

}

{
  my $s1 = String("hello");

  is($s1, String("hello"));
  is($s1, "hello");

  my $s2 = String(" world");

  is($s1 + $s2, String("hello world"));
  is($s1 + $s2, "hello world");
}
