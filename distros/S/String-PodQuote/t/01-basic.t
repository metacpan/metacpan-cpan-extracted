#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use String::PodQuote qw(pod_quote);

is(pod_quote("<>, C<=>, |, /"), "<E<gt>, CE<lt>=E<gt>, E<verbar>, E<sol>");

is(pod_quote("=foo"), "E<61>foo");
is(pod_quote("bar =foo"), "bar =foo");
is(pod_quote("\n=foo"), "\nE<61>foo");
is(pod_quote("\n\n=foo"), "\n\nE<61>foo");

is(pod_quote(" foo"), "E<32>foo");
is(pod_quote("\n foo"), "\nE<32>foo");
is(pod_quote("\n\n foo"), "\n\nE<32>foo");

is(pod_quote("\tfoo"), "E<9>foo");
is(pod_quote("\n\tfoo"), "\nE<9>foo");
is(pod_quote("\n\n\tfoo"), "\n\nE<9>foo");
is(pod_quote("bar\tfoo"), "bar\tfoo");

done_testing;
