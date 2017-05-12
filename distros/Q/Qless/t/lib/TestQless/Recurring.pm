package TestQless::Recurring;
use base qw(TestQless);
use Test::More;
use Test::Deep;
use List::Util qw(first);


sub test_interval_arg : Tests {
	my $self = shift;

	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_interval_arg'}, interval => 100, retries => 2);
	my $job = $self->{'client'}->jobs($jid);
	is $job->interval, 100;
	is $job->retries, 2;
	$jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_interval_arg'}, 200, retries => 3);
	$job = $self->{'client'}->jobs($jid);
	is $job->interval, 200;
	is $job->retries, 3;
}

# In this test, we want to enqueue a job and make sure that
# we can get some jobs from it in the most basic way. We should
# get jobs out of the queue every _k_ seconds
sub test_recur_on : Tests {
	my $self = shift;

	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_recur_on'}, interval => 1800);
	is $self->{'q'}->pop->complete, 'complete';
	is $self->{'q'}->pop, undef;
	$self->time_advance(1799);
	is $self->{'q'}->pop, undef;
	$self->time_advance(2);
	my $job = $self->{'q'}->pop;
	ok $job;
	is_deeply $job->data, {test => 'test_recur_on'};
	$job->complete;
	# We should not be able to pop a second job
	is $self->{'q'}->pop, undef;
	# Let's advance almost to the next one, and then check again
	$self->time_advance(1798);
	is $self->{'q'}->pop, undef;
	$self->time_advance(2);
	ok $self->{'q'}->pop;
	$self->time_unfreeze;
}

# Popped jobs should have the same priority, tags, etc. that the
# recurring job has
sub test_recur_attributes : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_recur_attributes'}, interval => 100, priority => -10, tags => ['foo', 'bar'], retries => 2);
	is $self->{'q'}->pop->complete, 'complete';
	for(1..10) {
		$self->time_advance(100);
		my $job = $self->{'q'}->pop;
		ok $job;
		is $job->priority, -10;
		is_deeply $job->tags, ['foo', 'bar'];
		is $job->original_retries, 2;

		ok first { $_ eq $job->jid } @{ $self->{'client'}->jobs->tagged('foo')->{'jobs'} };
		ok first { $_ eq $job->jid } @{ $self->{'client'}->jobs->tagged('bar')->{'jobs'} };
		ok !first { $_ eq $job->jid } @{ $self->{'client'}->jobs->tagged('hey')->{'jobs'} };
		
		$job->complete;
		is $self->{'q'}->pop, undef;
	}
	$self->time_unfreeze;
}

# In this test, we should get a job after offset and interval
# have passed
sub test_recur_offset : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_recur_offset'}, interval => 100, offset => 50);

	is $self->{'q'}->pop, undef;
	$self->time_advance(30);
	is $self->{'q'}->pop, undef;
	$self->time_advance(20);
	my $job = $self->{'q'}->pop;
	ok $job;
	$job->complete;
	# And henceforth we should have jobs periodically at 100 seconds
	$self->time_advance(99);
	is $self->{'q'}->pop, undef;
	$self->time_advance(2);
	ok $self->{'q'}->pop;

	$self->time_unfreeze;
}


# In this test, we want to make sure that we can stop recurring
# jobs
# We should see these recurring jobs crop up under queues when 
# we request them
sub test_recur_off : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_recur_off'}, interval => 100);
	is $self->{'q'}->pop->complete, 'complete';
	is $self->{'client'}->queues('testing')->counts->{'recurring'}, 1;
	is $self->{'client'}->queues->counts->[0]->{'recurring'}, 1;
	# Now, let's pop off a job, and then cancel the thing
	$self->time_advance(110);
	is $self->{'q'}->pop->complete, 'complete';
	my $job = $self->{'client'}->jobs($jid);
	is ref $job, 'Qless::RecurringJob';
	$job->cancel;
	is $self->{'client'}->queues('testing')->counts->{'recurring'}, 0;
	is $self->{'client'}->queues->counts->[0]->{'recurring'}, 0;
	$self->time_advance(1000);
	is $self->{'q'}->pop, undef;
	$self->time_unfreeze;
}



# We should be able to list the jids of all the recurring jobs
# in a queue
sub test_jobs_recur : Tests {
	my $self = shift;
	my @jids = map { $self->{'q'}->recur('Qless::Job', { 'test' => 'test_jobs_recur'}, interval => $_ * 10 ) } 1..10;
	is_deeply \@jids, $self->{'q'}->jobs->recurring;
	foreach my $jid (@jids) {
		is ref $self->{'client'}->jobs($jid), 'Qless::RecurringJob';
	}
}


# We should be able to get the data for a recurring job
sub test_recur_get : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_recur_get'}, interval => 100, priority => -10, tags => ['foo', 'bar'], retries => 2);
	my $job = $self->{'client'}->jobs($jid);
	is ref $job, 'Qless::RecurringJob';
	is $job->priority, -10;
	is $job->queue_name, 'testing';
	is_deeply $job->data, {test => 'test_recur_get'};
	is_deeply $job->tags, ['foo', 'bar'];
	is $job->interval, 100;
	is $job->retries, 2;
	is $job->count, 0;

	# Now let's pop a job
	$self->{'q'}->pop;
	is $self->{'client'}->jobs($jid)->count, 1;
	$self->time_unfreeze;
}

sub test_passed_interval : Tests {
	my $self = shift;
	# We should get multiple jobs if we've passed the interval time
	# several times.
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_passed_interval'}, interval => 100);
	is $self->{'q'}->pop->complete, 'complete';
	$self->time_advance(850);
	my @jobs = $self->{'q'}->pop(100);
	is scalar @jobs, 8;
	$_->complete foreach @jobs;

	# If we are popping fewer jobs than the number of jobs that would have
	# been scheduled, it should only make that many available
	$self->time_advance(800);
	@jobs = $self->{'q'}->pop(5);
	is scalar @jobs, 5;
	is $self->{'q'}->length, 5;
	$_->complete foreach @jobs;

	# Even if there are several recurring jobs, both of which need jobs
	# scheduled, it only pops off the needed number
	$jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_passed_interval_2'}, interval => 10);
	$self->time_advance(500);
	@jobs = $self->{'q'}->pop(5);
	is scalar @jobs, 5;
	is $self->{'q'}->length, 5;
	$_->complete foreach @jobs;

	# And if there are other jobs that are there, it should only move over
	# as many recurring jobs as needed
	$jid = $self->{'q'}->put('Qless::Job', {'foo'=>'bar'}, priority => 10);
	@jobs = $self->{'q'}->pop(5);
	is scalar @jobs, 5;
	is $self->{'q'}->length, 6;

	$self->time_unfreeze;
}

# We should see these recurring jobs crop up under queues when 
# we request them
sub test_queues_endpoint : Tests {
	my $self = shift;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_queues_endpoint'}, interval => 100);

	is $self->{'client'}->queues('testing')->counts->{'recurring'}, 1;
	is $self->{'client'}->queues->counts->[0]->{'recurring'}, 1;
}


# We should be able to change the attributes of a recurring job,
# and future spawned jobs should be affected appropriately. In
# addition, when we change the interval, the effect should be 
# immediate (evaluated from the last time it was run)
# We should be able to change the attributes of a recurring job,
# and future spawned jobs should be affected appropriately. In
# addition, when we change the interval, the effect should be 
# immediate (evaluated from the last time it was run)
sub test_change_attributes : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_change_attributes'}, interval => 1);
	is $self->{'q'}->pop->complete, 'complete';
	my $job = $self->{'client'}->jobs($jid);

	# First, test priority
	$self->time_advance(1);
	isnt $self->{'q'}->pop->priority, -10;
	isnt $self->{'client'}->jobs($jid)->priority, -10;
	$job->priority(-10);
	$self->time_advance(1);
	is $self->{'q'}->pop->priority, -10;
	is $self->{'client'}->jobs($jid)->priority, -10;

	# And data
	$self->time_advance(1);
	is_deeply $self->{'q'}->pop->data, {'test'=>'test_change_attributes'};
	is_deeply $self->{'client'}->jobs($jid)->data, {'test'=>'test_change_attributes'};
	$job->data({'foo' => 'bar'});
	$self->time_advance(1);
	is_deeply $self->{'q'}->pop->data, {'foo'=>'bar'};
	is_deeply $self->{'client'}->jobs($jid)->data, {'foo'=>'bar'};

	# And retries
	$self->time_advance(1);
	isnt $self->{'q'}->pop->original_retries, 10;
	isnt $self->{'client'}->jobs($jid)->retries, 10;
	$job->retries(10);
	$self->time_advance(1);
	is $self->{'q'}->pop->original_retries, 10;
	is $self->{'client'}->jobs($jid)->retries, 10;

	# And klass
	$self->time_advance(1);
	isnt $self->{'q'}->peek->klass, 'Qless::RecurringJob';
	isnt $self->{'q'}->pop->klass, 'Qless::RecurringJob';
	isnt $self->{'client'}->jobs($jid)->klass, 'Qless::RecurringJob';
	$job->klass('Qless::RecurringJob');
	$self->time_advance(1);
	is $self->{'q'}->peek->klass, 'Qless::RecurringJob';
	is $self->{'q'}->pop->klass, 'Qless::RecurringJob';
	is $self->{'client'}->jobs($jid)->klass, 'Qless::RecurringJob';

	$self->time_unfreeze;
}



# If we update a recurring job's interval, then we should get
# jobs from it as if it had been scheduled this way from the
# last time it had a job popped
sub test_change_interval : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_change_interval'}, interval => 100);
	is $self->{'q'}->pop->complete, 'complete';
	$self->time_advance(100);
	is $self->{'q'}->pop->complete, 'complete';
	$self->time_advance(50);
	# Now, let's update the interval to make it more frequent
	$self->{'client'}->jobs($jid)->interval(10);
	my @jobs = $self->{'q'}->pop(100);
	is scalar @jobs, 5;
	map { $_->complete } @jobs;
	# Now let's make the interval much longer
	$self->time_advance(49);
	$self->{'client'}->jobs($jid)->interval(1000);
	is $self->{'q'}->pop, undef;

	$self->time_advance(100);
	$self->{'client'}->jobs($jid)->interval(1000);
	is $self->{'q'}->pop, undef;

	$self->time_advance(849);
	$self->{'client'}->jobs($jid)->interval(1000);
	is $self->{'q'}->pop, undef;

	$self->time_advance(1);
	$self->{'client'}->jobs($jid)->interval(1000);
	is $self->{'q'}->pop, undef;

	$self->time_unfreeze;
}

# If we move a recurring job from one queue to another, then
# all future spawned jobs should be popped from that queue
sub test_move : Tests {
	my $self = shift;
	$self->time_freeze;
	my $jid = $self->{'q'}->recur('Qless::Job', {'test'=>'test_move'}, interval => 100);
	is $self->{'q'}->pop->complete, 'complete';
	$self->time_advance(110);
	is $self->{'q'}->pop->complete, 'complete';
	is $self->{'q'}->pop, undef;

	# Now let's move it to another queue
	$self->{'client'}->jobs($jid)->move('other');
	is $self->{'q'}->pop, undef;
	is $self->{'other'}->pop, undef;
	$self->time_advance(100);
	is $self->{'q'}->pop, undef;
	is $self->{'other'}->pop->complete, 'complete';
	is $self->{'client'}->jobs($jid)->queue_name, 'other';

	$self->time_unfreeze;
}

1;
