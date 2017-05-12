#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# population sample test

is(variancep(2,4,2,4), 1, "call variancep - functional interface");
is(stddevp(2,4,2,4),   1, "call stddevp - functional interface");
