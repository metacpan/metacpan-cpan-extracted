#!/usr/bin/perl

# Primitive tests, where if these fail, lots of others will too.

use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok( "Net::Traceroute" ); }

my $tr = Net::Traceroute->new(trace_program => "foo");
isa_ok($tr, "Net::Traceroute", "new isa Net::Traceroute");

is($tr->trace_program(), "foo", "attributes set by new are gettable");
$tr->trace_program("tracefoob");
is($tr->trace_program(), "tracefoob", "setter followed by getter does so");

$tr->queries(3);

my $clone = $tr->clone(queries => 2);

is(ref($clone), ref($tr), "clone returns same type as clonee");
is($clone->trace_program(), "tracefoob", "cloned attributes copy");
is($clone->queries(), 2, "clone can override attributes");
