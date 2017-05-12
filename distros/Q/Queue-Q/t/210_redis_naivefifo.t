use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestNaiveFIFO;

use Queue::Q::NaiveFIFO::Redis;

my ($Host, $Port) = get_redis_connect_info();
skip_no_redis() if not defined $Host;

my $q = Queue::Q::NaiveFIFO::Redis->new(
    server => $Host,
    port => $Port,
    queue_name => "test"
);
isa_ok($q, "Queue::Q::NaiveFIFO");
isa_ok($q, "Queue::Q::NaiveFIFO::Redis");

Queue::Q::TestNaiveFIFO::test_naive_fifo($q);

done_testing();
