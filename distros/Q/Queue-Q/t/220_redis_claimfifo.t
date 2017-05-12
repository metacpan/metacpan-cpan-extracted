use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestClaimFIFO;

use Queue::Q::ClaimFIFO::Redis;

my ($Host, $Port) = get_redis_connect_info();
skip_no_redis() if not defined $Host;

my $q = Queue::Q::ClaimFIFO::Redis->new(
    server => $Host,
    port => $Port,
    queue_name => "test"
);
isa_ok($q, "Queue::Q::ClaimFIFO");
isa_ok($q, "Queue::Q::ClaimFIFO::Redis");

Queue::Q::TestClaimFIFO::test_claim_fifo($q);

done_testing();
