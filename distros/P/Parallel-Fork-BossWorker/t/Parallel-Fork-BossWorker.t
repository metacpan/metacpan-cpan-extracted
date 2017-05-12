use strict;
use warnings;
use Test::More tests => 20;
BEGIN { use_ok('Parallel::Fork::BossWorker') };
require_ok('Parallel::Fork::BossWorker');

# Each entry in @testdata creates two additional tests
my @testdata = (
	{ value => 'ok' },
	{
		sleep => 10,
		crazybirds => 42,
		string => 'is this',
		arrayref => [0, 1, 2, 3],
	},
	{
		hashref => { foo => 'bar', baz => 'chas' },
	},
	{
		foo => { bar => { baz => 1 } },
	},
	{ data => 'here' },
	{ lots => 'of data' },
	{ need => 'testing' },
	{
		sleepy => 'thread',
		sleep => 2,
		iam => 'tired',
		all => 'the time',
		are => { you => ['there', 'at', 'all'] },
		question => '?',
	},
);

# How many results did we get back?
my $results_received = 0;

# Create new BossWorker instance
my $bw = new Parallel::Fork::BossWorker(
	worker_count => 5,
	work_handler => sub {
			my $work = shift;
			my $data = $work->{data};
			if ($data->{sleep}) {
				my $t1 = time();
				sleep($data->{sleep});
				my $t2 = time();
				$work->{slept} = $t2 - $t1;
			}
			return $work;
		},
	result_handler => sub {
		my $result = shift;
		is_deeply($result->{data}, $testdata[$result->{index}], "Verified \@testdata[$result->{index}]");
		is($result->{slept}, $result->{data}->{sleep}, "\@testdata[$result->{index}] slept as expected");
		$results_received++;
	}
);

isa_ok($bw, 'Parallel::Fork::BossWorker');

# Add work to the BW
foreach my $index (0..$#testdata) {
	$bw->add_work({index => $index, data => $testdata[$index]});
}

# Process the work in the queue
$bw->process();

is($results_received, scalar(@testdata), "Got all results back");
