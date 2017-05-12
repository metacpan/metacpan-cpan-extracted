#!/usr/bin/env perl

use strict;
use warnings;
use String::Urandom;

my $su = String::Urandom->new(
    LENGTH => 55,
    CHARS  => [ qw/ a b c 1 2 3 / ]
  );

my $length = $su->str_length;
my $chars  = $su->str_chars;
my $string = $su->rand_string;

print <<RESULTS;
   Length: $length
   Chars:  @$chars
   Result: $string
RESULTS
