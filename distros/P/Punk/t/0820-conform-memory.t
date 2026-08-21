#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PCConform;
use Punk::Cache;

# The contract battery, against the in-memory store.

conformance(sub {
    my (%opt) = @_;
    $opt{max_bytes} ||= 1024 * 1024;
    return Punk::Cache::Memory->new(%opt);
}, 'memory');

done_testing;
