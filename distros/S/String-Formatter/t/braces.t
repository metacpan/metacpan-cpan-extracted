#!perl
use strict;
use warnings;
use Test::More tests => 1;

use String::Formatter;

my $formatter = String::Formatter->new({
  codes => { s => sub { return $_[2] } }
});

my $unknown_fmt = "We know that %{nested {braces} rule}s.";
is(
  $formatter->format($unknown_fmt),
  "We know that nested {braces} rule.",
  "we allow braces inside braces",
);
