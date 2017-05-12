use strict;
use warnings;
use Protocol::SPDY::Stream;

use Test::More tests => 1;

isa_ok(my $stream = Protocol::SPDY::Stream->new, 'Protocol::SPDY::Stream', 'create new stream');
done_testing();
