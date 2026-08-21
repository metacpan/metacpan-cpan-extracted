#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use PCConform;
use Punk::Cache;

# The same battery, against the file store. Identical results, or the two are
# not interchangeable and the pluggable interface is a lie.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;

conformance(sub {
    my (%opt) = @_;
    $opt{max_bytes} ||= 1024 * 1024;
    return Punk::Cache::File->new(dir => "$root/c" . $n++, %opt);
}, 'file');

# THE SAME BATTERY, THROUGH A MEMORY TIER.
#
# The whole claim of the tier is that it changes how fast an answer arrives
# and nothing about what the answer is. This is where that is tested rather
# than asserted: the identical assertions, unmodified, against a file store
# with 1M of memory in front of it.
#
# A tier is exactly the sort of optimisation that passes every test written
# for it and breaks one written for something else - an expiry that the tier
# extends, a delete the tier does not see, a clear that empties one half. The
# battery already covers all three, so it is the cheapest real assurance
# available and it costs one call.
conformance(sub {
    my (%opt) = @_;
    $opt{max_bytes} ||= 1024 * 1024;
    return Punk::Cache->new(file => dir => "$root/t" . $n++, %opt,
                            memory => '1M', memory_ttl => 60);
}, 'file+tier');

done_testing;
