use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestReliableFIFO;

use Queue::Q::ReliableFIFO::Redis;

my ($Host, $Port) = get_redis_connect_info();
skip_no_redis() if not defined $Host;

my $q = Queue::Q::ReliableFIFO::Redis->new(
    server => $Host,
    port => $Port,
    queue_name => "test"
);
isa_ok($q, "Queue::Q::ReliableFIFO");
isa_ok($q, "Queue::Q::ReliableFIFO::Redis");

Queue::Q::TestReliableFIFO::test_claim_fifo($q);

done_testing();
