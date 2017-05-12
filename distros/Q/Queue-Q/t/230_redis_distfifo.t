use strict;
use warnings;
use File::Spec;
use Test::More;

use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib' );
use Queue::Q::Test;
use Queue::Q::TestDistFIFO;

use Queue::Q::NaiveFIFO::Redis;
use Queue::Q::ClaimFIFO::Redis;
use Queue::Q::DistFIFO;

my ($Host, $Port) = get_redis_connect_info();
skip_no_redis() if not defined $Host;

SCOPE: {
    my @q = map Queue::Q::NaiveFIFO::Redis->new(
                server => $Host,
                port => $Port,
                queue_name => "test$_"
            ), 1..5;

    isa_ok($_, "Queue::Q::NaiveFIFO") for @q;
    isa_ok($_, "Queue::Q::NaiveFIFO::Redis") for @q;

    my $q = Queue::Q::DistFIFO->new(
        shards => \@q,
    );
    isa_ok($q, "Queue::Q::DistFIFO");

    Queue::Q::TestDistFIFO::test_dist_fifo($q);
}

SCOPE: {
    my @q = map Queue::Q::ClaimFIFO::Redis->new(
                server => $Host,
                port => $Port,
                queue_name => "test$_"
            ), 1..5;

    isa_ok($_, "Queue::Q::ClaimFIFO") for @q;
    isa_ok($_, "Queue::Q::ClaimFIFO::Redis") for @q;

    my $q = Queue::Q::DistFIFO->new(
        shards => \@q,
    );
    isa_ok($q, "Queue::Q::DistFIFO");

    Queue::Q::TestDistFIFO::test_dist_fifo_claim($q);
}


done_testing();
