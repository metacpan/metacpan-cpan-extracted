use Test::Deep;
use Test::More;
use Data::Dumper;

use aliased 'Tapper::Schema::TestrunDB::Result::Queue';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::Algorithm::WFQ';
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;
use Tapper::MCP::Scheduler::Queue;

construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_empty.yml' );

my $algorithm = Algorithm->new_with_traits ( traits => [WFQ], queues => {} );
ok($algorithm->does(WFQ), 'does WFQ');



my %queues = (
              A => Tapper::MCP::Scheduler::Queue->new({name => 'A', priority => 300, runcount => 0}),
              B => Tapper::MCP::Scheduler::Queue->new({name => 'B', priority => 200, runcount => 0}),
              C => Tapper::MCP::Scheduler::Queue->new({name => 'C', priority => 100, runcount => 0}),
              D => Tapper::MCP::Scheduler::Queue->new({name => 'D', priority => 0, runcount => 0}),
             );

my @order;

push @order, $algorithm->get_next_queue(\%queues);
push @order, $algorithm->get_next_queue(\%queues);
push @order, $algorithm->get_next_queue(\%queues);
push @order, $algorithm->get_next_queue(\%queues);
push @order, $algorithm->get_next_queue(\%queues);
push @order, $algorithm->get_next_queue(\%queues);

my $right_order=['A','B','A','A','B','C'];
my @order_names = map { $_->name } @order;
cmp_bag(\@order_names, $right_order, 'Scheduling');

done_testing;
