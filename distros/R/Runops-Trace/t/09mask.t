#!perl

use strict;
use warnings;

use Runops::Trace;
use Test::More 'no_plan';

sub foo { shift() + 4 }

sub bar {
  my $x = 3;
  foo($x);
}

sub trace_bar {
  Runops::Trace::trace_code(\&bar);
}

Runops::Trace::mask_all();

is_deeply([ trace_bar() ], [], "no ops with mask_all");

Runops::Trace::unmask_op("entersub");

is_deeply([ map { $_->name } trace_bar() ], ["entersub"], "only entersub traced");

Runops::Trace::mask_none();

my @ops = trace_bar;

cmp_ok(scalar(@ops), ">=", 1, "more than 1 op traced this time");
