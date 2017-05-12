use Test::Deep;
use Test::More tests => 2;
use Data::Dumper;
use Tapper::Schema::TestTools;

use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm';
use Tapper::MCP::Scheduler::Queue;


my $algorithm = Algorithm->new_with_traits
    (
     traits => [DummyAlgorithm],
     queues => {}, # set explicitely later
    );
ok($algorithm->does(DummyAlgorithm), 'does DummyAlgorithm');


my @order;

my $A = Tapper::MCP::Scheduler::Queue->new(id => 1, name => 'A');
my $B = Tapper::MCP::Scheduler::Queue->new(id => 2, name => 'B');
my $C = Tapper::MCP::Scheduler::Queue->new(id => 3, name => 'C');

push @order, $algorithm->get_next_queue({a => $A, b => $B, c => $C});
push @order, $algorithm->get_next_queue({a => $A, b => $B, c => $C});
push @order, $algorithm->get_next_queue({a => $A, b => $B, c => $C});
push @order, $algorithm->get_next_queue({a => $A, b => $B, c => $C});
push @order, $algorithm->get_next_queue({b => $B, c => $C});
push @order, $algorithm->get_next_queue({c => $C});

my $right_order=['A','B','C','A','B','C'];
my @order_names = map { $_->name } @order;
is_deeply(\@order_names, $right_order, 'Scheduling');
