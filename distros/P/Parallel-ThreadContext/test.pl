use Parallel::ThreadContext;

my $counter = 0;
my $counter_ref = \\\\\\\\\\$counter;

sub op1
{
	my $job = shift @_;
	Parallel::ThreadContext::abortCurrentThread("I am tired of living") if ($job == 30);
	Parallel::ThreadContext::println("performing job $job in Context ".Parallel::ThreadContext::getContextName());
	Parallel::ThreadContext::pauseCurrentThread(1);
	Parallel::ThreadContext::reserveLock("counterlock","computation");
	$counter++;
	Parallel::ThreadContext::releaseLock("counterlock","computation");
}

$Parallel::ThreadContext::debug = 1;
print STDOUT Parallel::ThreadContext::version();
my $nbthreads = Parallel::ThreadContext::getNoProcessors();
if (defined $nbthreads)
{
$nbthreads *= 3; #3 threads per processor
}
else
{
$nbthreads = 3;
}
Parallel::ThreadContext::shareVariable($counter_ref);
Parallel::ThreadContext::start(\&op1,[1..10],$nbthreads,"computation");
Parallel::ThreadContext::addJobsToQueue([11..20],"computation");
Parallel::ThreadContext::pauseCurrentThread(2);
Parallel::ThreadContext::addJobsToQueue([21..26],"computation");
Parallel::ThreadContext::pauseCurrentThread(4);
Parallel::ThreadContext::finalizeQueue("computation");
Parallel::ThreadContext::end("computation");
Parallel::ThreadContext::addJobsToQueue([27..30],"computation");
Parallel::ThreadContext::start(\&op1,[],1,"computation2");
Parallel::ThreadContext::finalizeQueue("computation2");
Parallel::ThreadContext::yieldRuntime("computation2");
Parallel::ThreadContext::end("computation2");
Parallel::ThreadContext::println("final counter value is $counter");