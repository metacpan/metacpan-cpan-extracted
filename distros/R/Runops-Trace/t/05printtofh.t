#!perl

use strict;
use warnings;
use Runops::Trace;
BEGIN { Runops::Trace::enable_tracing() }

use Test::More tests => 1;

# this segfaults when loading PerlIO::scalar
open my $tmp, '>', \my $out;
print $tmp "foo";
is($out, "foo", "print to PerlIO::scalar works");
