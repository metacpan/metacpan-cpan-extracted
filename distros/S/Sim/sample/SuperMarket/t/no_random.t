use Test::Base;
use File::Slurp;
use IPC::Run3;

plan tests => 4 * blocks();

run {
    my $block = shift;
    my $name = $block->name;
    my $cmd = [$^X, '-I../../lib', 'script/no_random.pl', $block->arrival_time, $block->service_time, 10];
    my $events;
    run3 $cmd, undef, \$events, \undef;
    is $?, 0, "$name - test.pl ran successfully";
    is $events, $block->events, "$name - event list okay";
    $cmd = [$^X, 'script/stats.pl'];
    my $stats;
    run3 $cmd, \$events, \$stats, \undef;
    is $?, 0, "$name - script/stats.pl ran successfully";
    is $stats, $block->stats, "$name - output okay";
};

__END__

=== TEST 1:
--- arrival_time: 2
--- service_time: 1
--- events
0..10
@2 <Server 0> <== Client 0
@2 <Server 0> serves Client 0.
@3 <Server 0> ==> Client 0
@4 <Server 0> <== Client 1
@4 <Server 0> serves Client 1.
@5 <Server 0> ==> Client 1
@6 <Server 0> <== Client 2
@6 <Server 0> serves Client 2.
@7 <Server 0> ==> Client 2
@8 <Server 0> <== Client 3
@8 <Server 0> serves Client 3.
@9 <Server 0> ==> Client 3
@10 <Server 0> <== Client 4
@10 <Server 0> serves Client 4.

--- stats
<Server 0>
  Customers in system: 0.4
  Customers in queue: 0
Total
  Customers in system: 0.4
  Customers in queue: 0
  Time in system: 1
  Time in queue: 0
  Service time: 1



=== TEST 2:
--- arrival_time: 1
--- service_time: 2
--- events
0..10
@1 <Server 0> <== Client 0
@1 <Server 0> serves Client 0.
@2 <Server 0> <== Client 1
@3 <Server 0> ==> Client 0
@3 <Server 0> serves Client 1.
@3 <Server 0> <== Client 2
@4 <Server 0> <== Client 3
@5 <Server 0> ==> Client 1
@5 <Server 0> serves Client 2.
@5 <Server 0> <== Client 4
@6 <Server 0> <== Client 5
@7 <Server 0> ==> Client 2
@7 <Server 0> serves Client 3.
@7 <Server 0> <== Client 6
@8 <Server 0> <== Client 7
@9 <Server 0> ==> Client 3
@9 <Server 0> serves Client 4.
@9 <Server 0> <== Client 8
@10 <Server 0> <== Client 9

--- stats
<Server 0>
  Customers in system: 2.9
  Customers in queue: 2
Total
  Customers in system: 2.9
  Customers in queue: 2
  Time in system: 3.5
  Time in queue: 2
  Service time: 2
