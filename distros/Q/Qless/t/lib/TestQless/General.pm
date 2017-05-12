package TestQless::General;
use base qw(TestQless);
use Test::More;
use Test::Deep;
use List::Util;

sub test_config : Tests(5) {
	my $self = shift;

	# Set this particular configuration value
	my $config = $self->{'client'}->config;
	$config->set('testing', 'foo');
	is $config->get('testing'), 'foo';

	# Now let's get all the configuration options and make
	# sure that it's a HASHREF, and that it has a key for 'testing'
	is ref $config->get, 'HASH';
	is $config->get->{'testing'}, 'foo';

	# Now we'll delete this configuration option and make sure that
	# when we try to get it again, it doesn't exist
	$config->del('testing');
	is $config->get('testing'), undef;
	ok(!exists $config->get->{'testing'});
}


# In this test, I want to make sure that I can put a job into
# a queue, and then retrieve its data
#   1) put in a job
#   2) get job
#   3) delete job
sub test_put_get : Tests(7) {
	my $self = shift;

	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'put_get'});
	my $put_time = time;
	my $job = $self->{'client'}->jobs($jid);

	is $job->priority, 0;
	is_deeply $job->data, {'test' => 'put_get' };
	is_deeply $job->tags, [];
	is $job->worker_name, '';
	is $job->state, 'waiting';
	is $job->klass, 'Qless::Job';
	is_deeply $job->history, [{
			'q' => 'testing',
			'put' => $put_time,
		}];
}


# In this test, I want to make sure that I can put a job into
# a queue, and then retrieve its data
#   1) put in a job
#   2) get job
#   3) delete job
sub test_push_peek_pop_many : Tests(6) {
	my $self = shift;

	is $self->{'q'}->length, 0, 'Starting with empty queue';

	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'push_pop_many', count => $_ }) } 1..10;
	is $self->{'q'}->length, scalar @jids, 'Inserting should increase the size of the queue';

	# Alright, they're in the queue. Let's take a peek
	is scalar $self->{'q'}->peek(7), 7;
	is scalar $self->{'q'}->peek(10), 10;

	# Now let's pop them all off one by one
	is scalar $self->{'q'}->pop(7), 7;
	is scalar $self->{'q'}->pop(10), 3;
}


# In this test, we want to put a job, pop a job, and make
# sure that when popped, we get all the attributes back 
# that we expect
#   1) put a job
#   2) pop said job, check existence of attributes
sub test_put_pop_attributes : Tests(12) {
	my $self = shift;

	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'test_put_pop_attributes'});
	$self->{'client'}->config->set('heartbeat', 60);

	my $job = $self->{'q'}->pop;

	is_deeply $job->data, {'test'=>'test_put_pop_attributes'};
	is $job->worker_name, $self->{'client'}->worker_name;
	ok $job->ttl > 0;
	is $job->state, 'running';
	is $job->queue_name, 'testing';
	is $job->queue->name, 'testing';
	is $job->retries_left, 5;
	is $job->original_retries, 5;
	is $job->jid, $jid;
	is $job->klass, 'Qless::Job';
	is_deeply $job->tags, [];

	$jid = $self->{'q'}->put('Foo::Job', {'test'=>'test_put_pop_attributes'});
	$job = $self->{'q'}->pop;
	is $job->klass, 'Foo::Job';
}


# In this test, we're going to add several jobs and make
# sure that we get them in an order based on priority
#   1) Insert 10 jobs into the queue with successively more priority
#   2) Pop all the jobs, and ensure that with each pop we get the right one
sub test_put_pop_priority : Tests(11) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'put_pop_priority', count => $_ }, priority => $_) }  0..9;
	my $last = scalar @jids;
	foreach (@jids) {
		my $job = $self->{'q'}->pop;
		ok $job->data->{'count'} < $last, 'We should see jobs in reverse order';
		$last = $job->data->{'count'};
	}
}


# In this test, we want to make sure that jobs are popped
# off in the same order they were put on, priorities being
# equal.
#   1) Put some jobs
#   2) Pop some jobs, save jids
#   3) Put more jobs
#   4) Pop until empty, saving jids
#   5) Ensure popped jobs are in the same order
sub test_same_priority_order : Tests(1) {
	my $self = shift;
	my $jids   = [];
	my $popped = [];
	for(0..99) {
		push @{ $jids }, $self->{'q'}->put('Qless::Job', { 'test' => 'put_pop_order', 'count' => 2*$_ });
		$self->{'q'}->peek;
		push @{ $jids }, $self->{'q'}->put('Foo::Job', { 'test' => 'put_pop_order', 'count' => 2*$_+1 });
		push @{ $popped }, $self->{'q'}->pop->jid;
		$self->{'q'}->peek;
	}

	
	push @{ $popped }, map { $self->{'q'}->pop->jid } 0..99;

	is_deeply $jids, $popped;
}


# In this test, we'd like to make sure that we can't pop
# off a job scheduled for in the future until it has been
# considered valid
#   1) Put a job scheduled for 10s from now
#   2) Ensure an empty pop
#   3) 'Wait' 10s
#   4) Ensure pop contains that job
# This is /ugly/, but we're going to path the time function so
# that we can fake out how long these things are waiting
sub test_scheduled : Tests(5) {
	my $self = shift;

	is $self->{'q'}->length, 0, 'Starting with empty queue';

	$self->time_freeze;

	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'scheduled'}, delay => 10);

	is $self->{'q'}->pop, undef;
	is $self->{'q'}->length, 1;

	$self->time_advance(11);

	my $job = $self->{'q'}->pop;
	ok $job;
	is $job->jid, $jid;

	$self->time_unfreeze;
}


# Despite the wordy test name, we want to make sure that
# when a job is put with a delay, that its state is 
# 'scheduled', when we peek it or pop it and its state is
# now considered valid, then it should be 'waiting'
sub test_scheduled_peek_pop_state : Tests(3) {
	my $self = shift;

	$self->time_freeze;

	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'scheduled_state'}, delay => 10);
	is $self->{'client'}->jobs($jid)->state, 'scheduled';

	$self->time_advance(11);

	is $self->{'q'}->peek->state, 'waiting';
	is $self->{'client'}->jobs($jid)->state, 'waiting';

	$self->time_unfreeze;
}


# In this test, we want to put a job, pop it, and then 
# verify that its history has been updated accordingly.
#   1) Put a job on the queue
#   2) Get job, check history
#   3) Pop job, check history
#   4) Complete job, check history
sub test_put_pop_complete_history : Tests(3) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';

	my $put_time = time;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'put_history'});
	my $job = $self->{'client'}->jobs($jid);
	is $job->history->[0]->{'put'}, $put_time;

	my $pop_time = time;
	$job = $self->{'q'}->pop;
	$job = $self->{'client'}->jobs($jid);
	is $job->history->[0]->{'popped'}, $pop_time;
}


# In this test, we want to verify that if we put a job
# in one queue, and then move it, that it is in fact
# no longer in the first queue.
#   1) Put a job in one queue
#   2) Put the same job in another queue
#   3) Make sure that it's no longer in the first queue
sub test_move_queue : Tests(5) {
	my $self = shift;

	is $self->{'q'}->length, 0, 'Starting with empty queue';
	is $self->{'other'}->length, 0, 'Starting with empty other queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'move_queue'});
	is $self->{'q'}->length, 1;
	my $job = $self->{'client'}->jobs($jid);
	$job->move('other');
	is $self->{'q'}->length, 0;
	is $self->{'other'}->length, 1;
}


# In this test, we want to verify that if we put a job
# in one queue, it's popped, and then we move it before
# it's turned in, then subsequent attempts to renew the
# lock or complete the work will fail
#   1) Put job in one queue
#   2) Pop that job
#   3) Put job in another queue
#   4) Verify that heartbeats fail
sub test_move_queue_popped : Tests(5) {
	my $self = shift;

	is $self->{'q'}->length, 0, 'Starting with empty queue';
	is $self->{'other'}->length, 0, 'Starting with empty other queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'move_queue_popped'});
	is $self->{'q'}->length, 1;
	$job = $self->{'q'}->pop;
	ok $job;
	$job->move('other');
	is $job->heartbeat, 0;
}


# In this test, we want to verify that if we move a job
# from one queue to another, that it doesn't destroy any
# of the other data that was associated with it. Like 
# the priority, tags, etc.
#   1) Put a job in a queue
#   2) Get the data about that job before moving it
#   3) Move it 
#   4) Get the data about the job after
#   5) Compare 2 and 4  
sub test_move_non_destructive : Tests(8) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	is $self->{'other'}->length, 0, 'Starting with empty other queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'move_non_destructive'}, tags => ['foo', 'bar'], priority => 5);

	my $before = $self->{'client'}->jobs($jid);
	$before->move('other');
	my $after = $self->{'client'}->jobs($jid);

	is_deeply $before->tags, ['foo', 'bar'];
	is $before->priority, 5;
	is_deeply $before->tags, $after->tags;
	is_deeply $before->data, $after->data;
	is_deeply $before->priority, $after->priority;
	is scalar @{ $after->history }, 2;
}


# In this test, we want to make sure that we can still 
# keep our lock on an object if we renew it in time.
# The gist of this test is:
#   1) A gets an item, with positive heartbeat
#   2) B tries to get an item, fails
#   3) A renews its heartbeat successfully
sub test_heartbeat : Tests(7) {
	my $self = shift;
	is $self->{'a'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'heartbeat'});
	my $ajob = $self->{'a'}->pop;
	ok $ajob;
	my $bjob = $self->{'a'}->pop;
	ok !$bjob;
	ok $ajob->heartbeat =~ /^\d+(\.\d+)?$/;
	ok $ajob->ttl > 0;
	$self->{'q'}->heartbeat(-60);
	ok $ajob->heartbeat =~ /^\d+(\.\d+)?$/;
	ok $ajob->ttl <= 0;
}


# In this test, we want to make sure that when we heartbeat a 
# job, its expiration in the queue is also updated. So, supposing
# that I heartbeat a job 5 times, then its expiration as far as
# the lock itself is concerned is also updated
sub test_heartbeat_expiration : Tests(21) {
	my $self = shift;

	$self->{'client'}->config->set('crawl-heartbeat', 7200);
	my $jid = $self->{'q'}->put('Qless::Job', {});

	my $job = $self->{'a'}->pop;
	ok !$self->{'b'}->pop;
	$self->time_freeze;
	for (1..10) {
		$self->time_advance(3600);
		ok $job->heartbeat;
		ok !$self->{'b'}->pop;
	}
	$self->time_unfreeze;
}


# In this test, we want to make sure that we cannot heartbeat
# a job that has not yet been popped
#   1) Put a job
#   2) DO NOT pop that job
#   3) Ensure we cannot heartbeat that job
sub test_heartbeat_state : Tests(2) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'heartbeat_state'});
	my $job = $self->{'client'}->jobs($jid);
	ok !$job->heartbeat;
}


# Make sure that we can safely pop from an empty queue
#   1) Make sure the queue is empty
#   2) When we pop from it, we don't get anything back
#   3) When we peek, we don't get anything
sub test_peek_pop_empty : Tests(3) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	ok !$self->{'q'}->pop;
	ok !$self->{'q'}->peek;
}


# In this test, we want to put a job and peek that job, we 
# get all the attributes back that we expect
#   1) put a job
#   2) peek said job, check existence of attributes
sub test_peek_attributes : Tests(11) {
	my $self = shift;

	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'peek_attributes'});
	my $job = $self->{'q'}->peek;

	is_deeply $job->data, {'test'=>'peek_attributes'};
	is $job->worker_name, '';
	is $job->state, 'waiting';
	is $job->queue_name, 'testing';
	is $job->queue->name, 'testing';
	is $job->retries_left, 5;
	is $job->original_retries, 5;
	is $job->jid, $jid;
	is $job->klass, 'Qless::Job';
	is_deeply $job->tags, [];

	$jid = $self->{'q'}->put('Foo::Job', {'test'=>'peek_attributes'});
	$job = $self->{'q'}->pop;
	$job = $self->{'q'}->peek;
	is $job->klass, 'Foo::Job';
}


# In this test, we're going to have two queues that point
# to the same queue, but we're going to have them represent
# different workers. The gist of it is this
#   1) A gets an item, with negative heartbeat
#   2) B gets the same item,
#   3) A tries to renew lock on item, should fail
#   4) B tries to renew lock on item, should succeed
#   5) Both clean up
sub test_locks : Tests(6) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'locks'});
	# Reset our heartbeat for both A and B
	$self->{'client'}->config->set('heartbeat', -10);

	# Make sure a gets a job
	my $ajob = $self->{'a'}->pop;
	ok $ajob;

	# Now, make sure that b gets that same job
	my $bjob = $self->{'b'}->pop;
	ok $bjob;
	is $ajob->jid, $bjob->jid;
	ok $bjob->heartbeat =~ /^\d+(\.\d+)?$/;
	ok $bjob->heartbeat + 11 >= time;
	ok !$ajob->heartbeat;
}


# When a worker loses a lock on a job, that job should be removed
# from the list of jobs owned by that worker
sub test_locks_workers : Tests(5) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'locks'}, retries => 1);
	$self->{'client'}->config->set('heartbeat', -10);
	my $ajob = $self->{'a'}->pop;

	# Get the workers
	my $workers = +{ map { $_->{'name'} => $_ } @{ $self->{'client'}->workers->counts } };
	is $workers->{ $self->{'a'}->worker_name }->{'stalled'}, 1;

	# Should have one more retry, so we should be good
	my $bjob = $self->{'b'}->pop;
	$workers = +{ map { $_->{'name'} => $_ } @{ $self->{'client'}->workers->counts } };
	is $workers->{ $self->{'a'}->worker_name }->{'stalled'}, 0;
	is $workers->{ $self->{'b'}->worker_name }->{'stalled'}, 1;

	# Now it's automatically failed. Shouldn't appear in either worker
	$bjob = $self->{'b'}->pop;
	$workers = +{ map { $_->{'name'} => $_ } @{ $self->{'client'}->workers->counts } };
	is $workers->{ $self->{'a'}->worker_name }->{'stalled'}, 0;
	is $workers->{ $self->{'b'}->worker_name }->{'stalled'}, 0;
}


# In this test, we want to make sure that we can corretly
# cancel a job
#   1) Put a job
#   2) Cancel a job
#   3) Ensure that it's no longer in the queue
#   4) Ensure that we can't get data for it
sub test_cancel : Tests(4) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'cancel'});
	my $job = $self->{'client'}->jobs($jid);

	is $self->{'q'}->length, 1;
	$job->cancel;
	is $self->{'q'}->length, 0;
	is $self->{'client'}->jobs($jid), undef;
}



# In this test, we want to make sure that when we cancel
# a job, that heartbeats fail, as do completion attempts
#   1) Put a job
#   2) Pop that job
#   3) Cancel that job
#   4) Ensure that it's no longer in the queue
#   5) Heartbeats fail, Complete fails
#   6) Ensure that we can't get data for it
sub test_cancel_heartbeat : Tests(5) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'cancel_heartbeat'});
	my $job = $self->{'q'}->pop;
	$job->cancel;
	is $self->{'q'}->length, 0;
	ok !$job->heartbeat;
	ok !$job->complete;
	is $self->{'client'}->jobs($jid), undef;
}


# In this test, we want to make sure that if we fail a job
# and then we cancel it, then we want to make sure that when
# we ask for what jobs failed, we shouldn't see this one
#   1) Put a job
#   2) Fail that job
#   3) Make sure we see failure stats
#   4) Cancel that job
#   5) Make sure that we don't see failure stats
sub test_cancel_fail : Tests(2) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'cancel_fail'});
	my $job = $self->{'q'}->pop;
	$job->fail('foo', 'some message');
	is_deeply $self->{'client'}->jobs->failed, { 'foo' => 1 };
	$job->cancel;
	is_deeply $self->{'client'}->jobs->failed, {};
}


# In this test, we want to make sure that a job that has been
# completed and not simultaneously enqueued are correctly 
# marked as completed. It should have a complete history, and
# have the correct state, no worker, and no queue
#   1) Put an item in a queue
#   2) Pop said item from the queue
#   3) Complete that job
#   4) Get the data on that job, check state
sub test_complete : Tests(10) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'complete'});
	my $job = $self->{'q'}->pop;
	ok $job;
	is $job->complete, 'complete';
	$job = $self->{'client'}->jobs($jid);
	is $job->history->[0]->{'done'}, time;
	is $job->state, 'complete';
	is $job->worker_name, '';
	is $job->queue_name, '';
	is $self->{'q'}->length, 0;
	is_deeply $self->{'client'}->jobs->complete, [$jid];

	# Now, if we move job back into a queue, we shouldn't see any
	# completed jobs anymore
	$job->move('testing');
	is_deeply $self->{'client'}->jobs->complete, [];
}



# In this test, we want to make sure that a job that has been
# completed and simultaneously enqueued has the correct markings.
# It shouldn't have a worker, its history should be updated,
# and the next-named queue should have that item.
#   1) Put an item in a queue
#   2) Pop said item from the queue
#   3) Complete that job, re-enqueueing it
#   4) Get the data on that job, check state
#   5) Ensure that there is a work item in that queue
sub test_complete_advance : Tests(11) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'complete_advance'});
	my $job = $self->{'q'}->pop;
	ok $job;
	is $job->complete('testing'), 'waiting';
	$job = $self->{'client'}->jobs($jid);
	is scalar @{ $job->history }, 2;
	is $job->history->[0]->{'done'}, time;
	is $job->history->[1]->{'put'}, time;
	is $job->state, 'waiting';
	is $job->worker_name, '';
	is $job->queue_name, 'testing';
	is $job->queue->name, 'testing';
	is $self->{'q'}->length, 1;
}


# In this test, we want to make sure that a job that has been
# handed out to a second worker can both be completed by the
# second worker, and not completed by the first.
#   1) Hand a job out to one worker, expire
#   2) Hand a job out to a second worker
#   3) First worker tries to complete it, should fail
#   4) Second worker tries to complete it, should succeed
sub test_complete_fail : Tests(9) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'complete_fail'});
	$self->{'client'}->config->set('heartbeat', -10);
	my $ajob = $self->{'a'}->pop;
	ok $ajob;
	my $bjob = $self->{'b'}->pop;
	ok $bjob;

	is $ajob->complete, undef;
	is $bjob->complete, 'complete';

	my $job = $self->{'client'}->jobs($jid);
	is $job->state, 'complete';
	is $job->worker_name, '';
	is $job->queue_name, '';
	is $self->{'q'}->length, 0;
}


# In this test, we want to make sure that if we try to complete
# a job that's in anything but the 'running' state.
#   1) Put an item in a queue
#   2) DO NOT pop that item from the queue
#   3) Attempt to complete the job, ensure it fails
sub test_complete_state : Tests(2) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'complete_state'});
	my $job = $self->{'client'}->jobs($jid);
	is $job->complete('testing'), undef;
}



# In this test, we want to make sure that if we complete a job and
# advance it, that the new queue always shows up in the 'queues'
# endpoint.
#   1) Put an item in a queue
#   2) Complete it, advancing it to a different queue
#   3) Ensure it appears in 'queues'
sub test_complete_queues : Tests(3) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'complete_queues'});

	is scalar (grep { $_->{'name'} eq 'other' } @{ $self->{'client'}->queues->counts }), 0;
	$self->{'q'}->pop->complete('other');
	is scalar (grep { $_->{'name'} eq 'other' } @{ $self->{'client'}->queues->counts }), 1;
}



# In this test, we want to make sure that we honor our job
# expiration, in the sense that when jobs are completed, we 
# then delete all the jobs that should be expired according
# to our deletion criteria
#   1) First, set jobs-history-count to 10
#   2) Then, insert 20 jobs
#   3) Pop each of these jobs
#   4) Complete each of these jobs
#   5) Ensure that we have data about 10 jobs
sub test_job_count_expiration : Tests(2) {
	my $self = shift;
	$self->{'client'}->config->set('jobs-history-count', 10);
	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'job_count_expiration', count => $_ }) } 0..19;
	foreach (@jids) {
		$self->{'q'}->pop->complete;
	}

	is $self->{'redis'}->zcard('ql:completed'), 10;
	is scalar ($self->{'redis'}->keys('ql:j:*')), 10;
}


# In this test, we're going to make sure that statistics are
# correctly collected about how long items wait in a queue
#   1) Ensure there are no wait stats currently
#   2) Add a bunch of jobs to a queue
#   3) Pop a bunch of jobs from that queue, faking out the times
#   4) Ensure that there are now correct wait stats
sub test_stats_waiting : Tests(29) {
	my $self = shift;
	my $stats = $self->{'q'}->stats;
	is $stats->{'wait'}->{'count'}, 0;
	is $stats->{'run'}->{'count'}, 0;

	$self->time_freeze;
	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'stats_waiting', count => $_ }) } 0..19;
	is scalar @jids, 20;
	foreach (@jids) {
		ok $self->{'q'}->pop;
		$self->time_advance(1);
	}
	$self->time_unfreeze;

	# Now, make sure that we see stats for the waiting
	$stats = $self->{'q'}->stats;
	is $stats->{'wait'}->{'count'}, 20;
	is $stats->{'wait'}->{'mean'}, 9.5;
	# This is our expected standard deviation
	ok $stats->{'wait'}->{'std'} - 5.916079783099 < 1e-8;
	# Now make sure that our histogram looks like what we think it
	# should
	is_deeply [ @{ $stats->{'wait'}->{'histogram'} }[0..19] ], [ (1)x20 ];
	is List::Util::sum(@{ $stats->{'run'}->{'histogram'} }), $stats->{'run'}->{'count'};
	is List::Util::sum(@{ $stats->{'wait'}->{'histogram'} }), $stats->{'wait'}->{'count'};
}


# In this test, we want to make sure that statistics are
# correctly collected about how long items take to actually 
# get processed.
#   1) Ensure there are no run stats currently
#   2) Add a bunch of jobs to a queue
#   3) Pop those jobs
#   4) Complete those jobs, faking out the time
#   5) Ensure that there are now correct run stats
sub test_stats_complete : Tests(9) {
	my $self = shift;
	my $stats = $self->{'q'}->stats;
	is $stats->{'wait'}->{'count'}, 0;
	is $stats->{'run'}->{'count'}, 0;

	$self->time_freeze;
	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'stats_waiting', count => $_ }) } 0..19;
	my @jobs = $self->{'q'}->pop(20);
	is scalar @jobs, 20;
	foreach my $job (@jobs) {
		$job->complete;
		$self->time_advance(1);
	}
	$self->time_unfreeze;

	$stats = $self->{'q'}->stats;
	is $stats->{'run'}->{'count'}, 20;
	is $stats->{'run'}->{'mean'}, 9.5;
	ok $stats->{'run'}->{'std'} - 5.916079783099 < 1e-8;
	is_deeply [ @{ $stats->{'run'}->{'histogram'} }[0..19] ], [ (1)x20 ];
	is List::Util::sum(@{ $stats->{'run'}->{'histogram'} }), $stats->{'run'}->{'count'};
	is List::Util::sum(@{ $stats->{'wait'}->{'histogram'} }), $stats->{'wait'}->{'count'};
}


# In this test, we want to make sure that the queues function
# can correctly identify the numbers associated with that queue
#   1) Make sure we get nothing for no queues
#   2) Put delayed item, check
#   3) Put item, check
#   4) Put, pop item, check
#   5) Put, pop, lost item, check
sub test_queues : Tests(10) {
	my $self = shift;
	is $self->{'q'}->length, 0, 'Starting with empty queue';
	is_deeply $self->{'client'}->queues->counts, [];
	# Now, let's actually add an item to a queue, but scheduled
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'queues'}, delay => 10);
	my $expected = {
		'name'      => 'testing',
		'stalled'   => 0,
		'waiting'   => 0,
		'running'   => 0,
		'scheduled' => 1,
		'depends'   =>  0,
		'recurring' => 0
	};
	is_deeply $self->{'client'}->queues->counts, [$expected];
	is_deeply $self->{'client'}->queues('testing')->counts, $expected;

	$self->{'q'}->put('Qless::Job', {'test'=>'queues'});
	$expected->{'waiting'} += 1;
	is_deeply $self->{'client'}->queues->counts, [$expected];
	is_deeply $self->{'client'}->queues('testing')->counts, $expected;

	my $job = $self->{'q'}->pop;
	$expected->{'waiting'} -= 1;
	$expected->{'running'} += 1;
	is_deeply $self->{'client'}->queues->counts, [$expected];
	is_deeply $self->{'client'}->queues('testing')->counts, $expected;

	# Now we'll have to mess up our heartbeat to make this work
	$self->{'q'}->put('Qless::Job', {'test'=>'queues'});
	$self->{'client'}->config->set('heartbeat', -10);
	$job = $self->{'q'}->pop;
	$expected->{'stalled'} += 1;
	is_deeply $self->{'client'}->queues->counts, [$expected];
	is_deeply $self->{'client'}->queues('testing')->counts, $expected;
}


# In this test, we want to make sure that tracking works as expected.
#   1) Check tracked jobs, expect none
#   2) Put, Track a job, check
#   3) Untrack job, check
#   4) Track job, cancel, check
sub test_track : Tests(4) {
	my $self = shift;

	is_deeply $self->{'client'}->jobs->tracked, { expired => {}, jobs => [] };
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'track'});
	my $job = $self->{'client'}->jobs($jid);
	$job->track;
	
	is scalar @{ $self->{'client'}->jobs->tracked->{'jobs'} }, 1;
	$job->untrack;
	is scalar @{ $self->{'client'}->jobs->tracked->{'jobs'} }, 0;

	$job->track;
	$job->cancel;
	is scalar @{ $self->{'client'}->jobs->tracked->{'expired'} }, 1;
}


# When peeked, popped, failed, etc., qless should know when a 
# job is tracked or not
# => 1) Put a job, track it
# => 2) Peek, ensure tracked
# => 3) Pop, ensure tracked
# => 4) Fail, check failed, ensure tracked
sub test_track_tracked : Tests(3) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'track'});
	my $job = $self->{'client'}->jobs($jid);
	$job->track;
	is $self->{'q'}->peek->tracked, 1;

	$job = $self->{'q'}->pop;
	is $job->tracked, 1;

	$job->fail('foo', 'bar');
	is $self->{'client'}->jobs->failed('foo')->{'jobs'}->[0]->tracked, 1;
}


# When peeked, popped, failed, etc., qless should know when a 
# job is not tracked
# => 1) Put a job
# => 2) Peek, ensure not tracked
# => 3) Pop, ensure not tracked
# => 4) Fail, check failed, ensure not tracked
sub test_track_untracked : Tests(3) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'track'});
	my $job = $self->{'client'}->jobs($jid);
	is $self->{'q'}->peek->tracked, 0;

	$job = $self->{'q'}->pop;
	is $job->tracked, 0;

	$job->fail('foo', 'bar');
	is $self->{'client'}->jobs->failed('foo')->{'jobs'}->[0]->tracked, 0;
}


# In this test, we want to make sure that jobs are given a
# certain number of retries before automatically being considered
# failed.
#   1) Put a job with a few retries
#   2) Verify there are no failures
#   3) Lose the heartbeat as many times
#   4) Verify there are failures
#   5) Verify the queue is empty
sub test_retries : Tests(9) {
	my $self = shift;
	
	is_deeply $self->{'client'}->jobs->failed, {};
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'retries'}, retries => 2);
	# Easier to lose the heartbeat lock
	$self->{'client'}->config->set('heartbeat', -10);
	ok $self->{'q'}->pop;
	is_deeply $self->{'client'}->jobs->failed, {};
	ok $self->{'q'}->pop;
	is_deeply $self->{'client'}->jobs->failed, {};
	ok $self->{'q'}->pop;
	is_deeply $self->{'client'}->jobs->failed, {};

	# This one should do it
	is $self->{'q'}->pop, undef;
	is_deeply $self->{'client'}->jobs->failed, {'failed-retries-testing' => 1};
}


# In this test, we want to make sure that jobs have their number
# of remaining retries reset when they are put on a new queue
#   1) Put an item with 2 retries
#   2) Lose the heartbeat once
#   3) Get the job, make sure it has 1 remaining
#   4) Complete the job
#   5) Get job, make sure it has 2 remaining
sub test_retries_complete : Tests(3) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'retries_complete'}, retries => 2);
	$self->{'client'}->config->set('heartbeat', -10);
	my $job = $self->{'q'}->pop;
	ok $job;
	$job = $self->{'q'}->pop;
	is $job->retries_left, 1;
	$job->complete;

	$job = $self->{'client'}->jobs($jid);
	is $job->retries_left, 2;
}


# In this test, we want to make sure that jobs have their number
# of remaining retries reset when they are put on a new queue
#   1) Put an item with 2 retries
#   2) Lose the heartbeat once
#   3) Get the job, make sure it has 1 remaining
#   4) Re-put the job in the queue with job.move
#   5) Get job, make sure it has 2 remaining
sub test_retries_put : Tests(3) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'retries_put'}, retries => 2);
	$self->{'client'}->config->set('heartbeat', -10);
	my $job = $self->{'q'}->pop;
	ok $job;
	$job = $self->{'q'}->pop;
	is $job->retries_left, 1;
	$job->move('testing');
	$job = $self->{'client'}->jobs($jid);
	is $job->retries_left, 2;
}



# In this test, we want to make sure that statistics are
# correctly collected about how many items are currently failed
#   1) Put an item
#   2) Ensure we don't have any failed items in the stats for that queue
#   3) Fail that item
#   4) Ensure that failures and failed both increment
#   5) Put that item back
#   6) Ensure failed decremented, failures untouched
sub test_stats_failed : Tests(6) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'stats_failed'});
	my $stats = $self->{'q'}->stats;
	
	is $stats->{'failed'}, 0;
	is $stats->{'failures'}, 0;
	my $job = $self->{'q'}->pop;
	$job->fail('foo', 'bar');

	$stats = $self->{'q'}->stats;
	is $stats->{'failed'}, 1;
	is $stats->{'failures'}, 1;

	$job->move('testing');
	$stats = $self->{'q'}->stats;
	is $stats->{'failed'}, 0;
	is $stats->{'failures'}, 1;
}


# In this test, we want to make sure that retries are getting
# captured correctly in statistics
#   1) Put a job
#   2) Pop job, lose lock
#   3) Ensure no retries in stats
#   4) Pop job,
#   5) Ensure one retry in stats
sub test_stats_retries : Tests(2) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'stats_retries'});
	$self->{'client'}->config->set('heartbeat', -10);
	my $job = $self->{'q'}->pop;
	is $self->{'q'}->stats->{'retries'}, 0;
	$job = $self->{'q'}->pop;
	is $self->{'q'}->stats->{'retries'}, 1;
}


# In this test, we want to verify that if we unfail a job on a
# day other than the one on which it originally failed, that we
# the `failed` stats for the original day are decremented, not
# today.
#   1) Put a job
#   2) Fail that job
#   3) Advance the clock 24 hours
#   4) Put the job back
#   5) Check the stats with today, check failed = 0, failures = 0
#   6) Check 'yesterdays' stats, check failed = 0, failures = 1
sub test_stats_failed_original_day : Tests(6) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'stats_failed_original_day'});
	my $job = $self->{'q'}->pop;
	$job->fail('foo', 'bar');

	my $stats = $self->{'q'}->stats;
	is $stats->{'failed'}, 1;
	is $stats->{'failures'}, 1;

	$self->time_freeze;
	$self->time_advance(86400);

	$job->move('testing');
	# Now check tomorrow's stats
	my $today = $self->{'q'}->stats;
	is $today->{'failed'}, 0;
	is $today->{'failures'}, 0;
	$self->time_unfreeze;
	my $yesterday = $self->{'q'}->stats;
	is $yesterday->{'failed'}, 0;
	is $yesterday->{'failures'}, 1;
}


# In this test, we want to verify that when we add a job, we 
# then know about that worker, and that it correctly identifies
# the jobs it has.
#   1) Put a job
#   2) Ensure empty 'workers'
#   3) Pop that job
#   4) Ensure unempty 'workers'
#   5) Ensure unempty 'worker'
sub test_workers : Tests(3) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers'});
	is_deeply $self->{'client'}->workers->counts, [];
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 1,
			stalled => 0,
	}];
	# Now get specific worker information
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [$jid],
		stalled => [],
	};
}


# In this test, we want to verify that when a job is canceled,
# that it is removed from the list of jobs associated with a worker
#   1) Put a job
#   2) Pop that job
#   3) Ensure 'workers' and 'worker' know about it
#   4) Cancel job
#   5) Ensure 'workers' and 'worker' reflect that
sub test_workers_cancel : Tests(4) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers_cancel'});
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 1,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [$jid],
		stalled => [],
	};
	# Now cancel the job
	$job->cancel;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [],
	};
}


# In this test, we want to verify that 'workers' and 'worker'
# correctly identify that a job is stalled, and that when that
# job is taken from the lost lock, that it's no longer listed
# as stalled under the original worker. Also, that workers are
# listed in order of recency of contact
#   1) Put a job
#   2) Pop a job, with negative heartbeat
#   3) Ensure 'workers' and 'worker' show it as stalled
#   4) Pop the job with a different worker
#   5) Ensure 'workers' and 'worker' reflect that
sub test_workers_lost_lock : Tests(4) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers_lost_lock'});
	$self->{'client'}->config->set('heartbeat', -10);
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 1,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [$jid],
	};
	# Now, let's pop it with a different worker
	$self->{'client'}->config->del('heartbeat');
	$job = $self->{'a'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'a'}->worker_name,
			jobs => 1,
			stalled => 0,
	}, {
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [],
	};
}


# In this test, we want to make sure that when we fail a job,
# its reflected correctly in 'workers' and 'worker'
#   1) Put a job
#   2) Pop job, check 'workers', 'worker'
#   3) Fail that job
#   4) Check 'workers', 'worker'
sub test_workers_fail : Tests(4) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers_fail'});
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 1,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [$jid],
		stalled => [],
	};
	# Now, let's fail it
	$job->fail('foo', 'bar');
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [],
	};
}


# In this test, we want to make sure that when we complete a job,
# it's reflected correctly in 'workers' and 'worker'
#   1) Put a job
#   2) Pop a job, check 'workers', 'worker'
#   3) Complete job, check 'workers', 'worker'
sub test_workers_complete : Tests(4) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers_complete'});
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 1,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [$jid],
		stalled => [],
	};
	# Now complete it
	$job->complete;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [],
	};
}


# Make sure that if we move a job from one queue to another, that 
# the job is no longer listed as one of the jobs that the worker
# has.
#   1) Put a job
#   2) Pop job, check 'workers', 'worker'
#   3) Move job, check 'workers', 'worker'
sub test_workers_reput : Tests(4) {
	my $self = shift;
	my $jid = $self->{'q'}->put('Qless::Job', {'test'=>'workers_complete'});
	my $job = $self->{'q'}->pop;
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 1,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [$jid],
		stalled => [],
	};
	$job->move('other');
	is_deeply $self->{'client'}->workers->counts, [{
			name => $self->{'q'}->worker_name,
			jobs => 0,
			stalled => 0,
	}];
	is_deeply $self->{'client'}->workers($self->{'q'}->worker_name), {
		jobs => [],
		stalled => [],
	};
}


# Make sure that we can get a list of jids for a queue that
# are running, stalled and scheduled
#   1) Put a job, pop it, check 'running'
#   2) Put a job scheduled, check 'scheduled'
#   3) Put a job with negative heartbeat, pop, check stalled
#   4) Put a job dependent on another and check 'depends'
sub test_running_stalled_scheduled_depends : Tests(6) {
	my $self = shift;
	is $self->{'q'}->length, 0;
	# Now, we need to check pagination
	my @jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'rssd' }) } 0..19;
	$self->{'client'}->config->set('heartbeat', -60);
	my @jobs = $self->{'q'}->pop(20);
	cmp_bag [ @{ $self->{'q'}->jobs->stalled(0, 10) }, @{ $self->{'q'}->jobs->stalled(10, 10) } ], \@jids;

	$self->{'client'}->config->set('heartbeat', 60);
	@jobs = $self->{'q'}->pop(20);
	cmp_bag [ @{ $self->{'q'}->jobs->running(0, 10) }, @{ $self->{'q'}->jobs->running(10, 10) } ], \@jids;

	$_->complete foreach @jobs;
	@jids = reverse map { $_->jid } @jobs;
	is_deeply [ @{ $self->{'client'}->jobs->complete(0, 10) }, @{ $self->{'client'}->jobs->complete(10, 10) } ], \@jids;

	@jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'rssd' }, delay => 60) } 0..19;
	cmp_bag [ @{ $self->{'q'}->jobs->scheduled(0, 10) }, @{ $self->{'q'}->jobs->scheduled(10, 10) } ], \@jids;

	@jids = map { $self->{'q'}->put('Qless::Job', { 'test' => 'rssd' }, depends => \@jids) } 0..19;
	cmp_bag [ @{ $self->{'q'}->jobs->depends(0, 10) }, @{ $self->{'q'}->jobs->depends(10, 10) } ], \@jids;
}

1;
