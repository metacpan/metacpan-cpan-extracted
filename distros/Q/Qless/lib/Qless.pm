package Qless;
use strict; use warnings;
use Qless::Client;
our $VERSION = '0.06';



1;

__END__

=head1 NAME

Qless - perl bind for Qless job queueing system

=head1 DESCRIPTION

Qless is a powerful L<Redis|http://redis.io>-based job queueing system inspired by L<resque|https://github.com/defunkt/resque#readme>, but built on a collection of Lua scripts, maintained in the L<qless-core|https://github.com/seomoz/qless-core> repo.

=head2 Philosophy and Nomenclature

A job is a unit of work identified by a job id or jid. A queue can contain several jobs that are scheduled to be run at a certain time, several jobs that are waiting to run, and jobs that are currently running. A worker is a process on a host, identified uniquely, that asks for jobs from the queue, performs some process associated with that job, and then marks it as complete. When it's completed, it can be put into another queue.

Jobs can only be in one queue at a time. That queue is whatever queue they were last put in. So if a worker is working on a job, and you move it, the worker's request to complete the job will be ignored.

A job can be canceled, which means it disappears into the ether, and we'll never pay it any mind every again. A job can be dropped, which is when a worker fails to heartbeat or complete the job in a timely fashion, or a job can be failed, which is when a host recognizes some systematically problematic state about the job. A worker should only fail a job if the error is likely not a transient one; otherwise, that worker should just drop it and let the system reclaim it.

=head2 Features

1. B<Jobs don't get dropped on the floor> -- Sometimes workers drop jobs. Qless automatically picks them back up and gives them to another worker

2. B<Tagging / Tracking> -- Some jobs are more interesting than others. Track those jobs to get updates on their progress. Tag jobs with meaningful identifiers to find them quickly in the UI.

3. B<Job Dependencies> -- One job might need to wait for another job to complete

4. B<Stats> -- qless automatically keeps statistics about how long jobs wait to be processed and how long they take to be processed. Currently, we keep track of the count, mean, standard deviation, and a histogram of these times.

5. B<Job data is stored temporarily> -- Job info sticks around for a configurable amount of time so you can still look back on a job's history, data, etc.

6. B<Priority> -- Jobs with the same priority get popped in the order they were inserted; a higher priority means that it gets popped faster

7. B<Retry logic> -- Every job has a number of retries associated with it, which are renewed when it is put into a new queue or completed. If a job is repeatedly dropped, then it is presumed to be problematic, and is automatically failed.

8. B<Web App> -- With the advent of a Ruby client, there is a Sinatra-based web app that gives you control over certain operational issues (I<TDB - porting to perl PSGI app>)

9. B<Scheduled Work> -- Until a job waits for a specified delay (defaults to 0), jobs cannot be popped by workers

10. B<Recurring Jobs> -- Scheduling's all well and good, but we also support jobs that need to recur periodically.

11. B<Notifications> -- Tracked jobs emit events on pubsub channels as they get completed, failed, put, popped, etc. Use these events to get notified of progress on jobs you're interested in. B<NOT IMPLEMENTED>

Interest piqued? Then read on!

=head2 Installation

Install from CPAN:

C<sudo cpan Qless>

Alternatively, install qless-perl from source by checking it out from repository:

    hg clone ssh://hg@bitbucket.org/nuclon/qless-perl
    cd qless-perl
    perl Makefile.PL
    sudo make install

=head2 Enqueing Jobs

First things first, use Qless and create a client. The client accepts a Redis handler as a argument

    use Redis;
    use Qless;
    
    my $redis = Redis->new();
    my $client = Qless::Client->new($redis);

Jobs should be modules that define a process method, which must accept a single job argument:

    package MyJobClass;
    
    sub process {
        my ($self, $job) = @_;
    
        # $job is an instance of L<Qless::Job> and provides access to
        # $job->data, a means to cancel the job ($job->cancel), and more.
    }
    
    1;

Now you can access a queue, and add a job to that queue.

    # This references a new or existing queue 'testing'
    my $queue = $client->queues('testing');
    
    # Let's add a job, with some data. Returns Job ID
    $queue->put('MyJobClass', { hello => 'howdy' });
    # => "0c53b0404c56012f69fa482a1427ab7d"
    
    # Now we can ask for a job
    my $job = $queue->pop;
    # => <Qless::Job 0c53b0404c56012f69fa482a1427ab7d (MyJobClass / testing)>
    # And we can do the work associated with it!
    $job->process();

The job data must be serializable to JSON, and it is recommended that you use a hash for it. See below for a list of the supported job options.

The argument returned by C<$queue->put> is the job ID, or jid. Every Qless job has a unique jid, and it provides a means to interact with an existing job:

    # find an existing job by it's jid
    $job = $client->jobs->item($jid);
    
    # Query it to find out details about it:
    $job->klass # => the class of the job
    $job->queue # => the queue the job is in
    $job->data  # => the data for the job
    $job->history # => the history of what has happened to the job sofar
    $job->dependencies # => the jids of other jobs that must complete before this one
    $job->dependents # => the jids of other jobs that depend on this one
    $job->priority # => the priority of this job
    $job->tags # => array of tags for this job
    $job->original_retries # => the number of times the job is allowed to be retried
    $job->retries_left # => the number of retries left
    
    # You can also change the job in various ways:
    $job->move("some_other_queue"); # move it to a new queue
    $job->cancel; # cancel the job
    $job->tag("foo"); # add a tag
    $job->untag("foo"); # remove a tag


=head2 Running a Worker

=head2 Job Dependencies

Let's say you have one job that depends on another, but the task definitions are fundamentally different. You need to bake a turkey, and you need to make stuffing, but you can't make the turkey until the stuffing is made:

    my $queue        = $client->queues('cook')
    my $stuffing_jid = $queue->put('MakeStuffing', {lots => 'of butter'});
    my $turkey_jid   = $queue->put('MakeTurkey'  , {with => 'stuffing'}, depends => [$stuffing_jid])

When the stuffing job completes, the turkey job is unlocked and free to be processed.

=head2 Priority

Some jobs need to get popped sooner than others. Whether it's a trouble ticket, or debugging, you can do this pretty easily when you put a job in a queue:

    $queue->put('MyJobClass', {foo => 'bar'}, priority => 10);

What happens when you want to adjust a job's priority while it's still waiting in a queue?

    my $job = $client->jobs('0c53b0404c56012f69fa482a1427ab7d');
    $job->priority(10);
    # Now this will get popped before any job of lower priority


=head2 Scheduled Jobs

If you don't want a job to be run right away but some time in the future, you can specify a delay:

    # Run at least 10 minutes from now
    $queue->put('MyJobClass', {foo => 'bar'}, delay => 600);

This doesn't guarantee that job will be run exactly at 10 minutes. You can accomplish this by changing the job's priority so that once 10 minutes has elapsed, it's put before lesser-priority jobs:

    # Run in 10 minutes
    $queue->put('MyJobClass', {foo => 'bar'}, delay => 600, priority => 100);

=head2 Recurring Jobs

Sometimes it's not enough simply to schedule one job, but you want to run jobs regularly. In particular, maybe you have some batch operation that needs to get run once an hour and you don't care what worker runs it. Recurring jobs are specified much like other jobs:

    # Run every hour
    $queue->recur('MyJobClass', {widget => 'warble'}, 3600)
    # => 22ac75008a8011e182b24cf9ab3a8f3b

You can even access them in much the same way as you would normal jobs:

    my $job = $client->jobs->item('22ac75008a8011e182b24cf9ab3a8f3b');
    # => < Qless::RecurringJob 22ac75008a8011e182b24cf9ab3a8f3b >

Changing the interval at which it runs after the fact is trivial:

    # I think I only need it to run once every two hours
    $job->interval(7200);

If you want it to run every hour on the hour, but it's 2:37 right now, you can specify an offset which is how long it should wait before popping the first job:

    # 23 minutes of waiting until it should go
    $queue->recur('MyJobClass', {howdy => 'hello'}, 3600, offset => 23 * 60);

Recurring jobs also have priority, a configurable number of retries, and tags. These settings don't apply to the recurring jobs, but rather the jobs that they create. In the case where more than one interval passes before a worker tries to pop the job, more than one job is created. The thinking is that while it's completely client-managed, the state should not be dependent on how often workers are trying to pop jobs.

    # Recur every minute
    $queue->recur('MyJobClass', {lots => 'of jobs'}, 60);
    # ...
    # Wait 5 minutes
    scalar $queue->pop(10);
    # => 5 jobs got popped


=head2 Configuration Options

You can get and set global (read: in the context of the same Redis instance) configuration to change the behavior for heartbeating, and so forth. There aren't a tremendous number of configuration options, but an important one is how long job data is kept around. Job data is expired after it has been completed for jobs-history seconds, but is limited to the last jobs-history-count completed jobs. These default to 50k jobs, and 30 days, but depending on volume, your needs may change. To only keep the last 500 jobs for up to 7 days:

    $client->config->set('jobs-history', 7 * 86400);
	$client->config->set('jobs-history-count', 500);

=head2 Tagging / Tracking

In qless, 'tracking' means flagging a job as important. Tracked jobs have a tab reserved for them in the web interface, and they also emit subscribable events as they make progress (more on that below). You can flag a job from the web interface, or the corresponding code:

    $client->jobs('b1882e009a3d11e192d0b174d751779d')->track()

Jobs can be tagged with strings which are indexed for quick searches. For example, jobs might be associated with customer accounts, or some other key that makes sense for your project.

    $queue->put('GnomesJob', {'tags': 'aplenty'}, tags=>['12345', 'foo', 'bar']);

This makes them searchable in the web interface, or from code:

    $jids = $client->jobs->tagged('foo');

You can add or remove tags at will, too:

    $job = $client->jobs('b1882e009a3d11e192d0b174d751779d')
    $job->tag('howdy', 'hello');
    $job->untag('foo', 'bar')

=head2 Notifications

=head2 Retries

Workers sometimes die. That's an unfortunate reality of life. We try to mitigate the effects of this by insisting that workers heartbeat their jobs to ensure that they do not get dropped. That said, qless will automatically requeue jobs that do get 'stalled' up to the provided number of retries (default is 5). Since underpants profit can sometimes go awry, maybe you want to retry a particular heist several times:

    $queue->put('GnomesJob', {}, retries => 10);


=head2 Pop

A client pops one or more jobs from a queue:

    # Get a single job
    $job = $queue->pop();
    # Get 20 jobs
    $jobs = $queue->pop(20);


=head2 Heartbeating

Each job object has a notion of when you must either check in with a heartbeat or turn it in as completed. You can get the absolute time until it expires, or how long you have left:

    # When I have to heartbeat / complete it by (seconds since epoch)
    $job->expires_at;
    # How long until it expires
    $job->ttl;

If your lease on the job will expire before you have a chance to complete it, then you should heartbeat it to make sure that no other worker gets access to it. Or, if you are done, you should complete it so that the job can move on:

    # I call stay-offsies!
    $job->heartbeat();
    # I'm done!
    $job->complete();
    # I'm done with this step, but need to go into another queue
    $job->complete('anotherQueue');


=head2 Stats

One nice feature of qless is that you can get statistics about usage. Stats are aggregated by day, so when you want stats about a queue, you need to say what queue and what day you're talking about. By default, you just get the stats for today. These stats include information about the mean job wait time, standard deviation, and histogram. This same data is also provided for job completion:

    # So, how're we doing today?
    my $stats = $client->queue('testing')->stats;
    # => { 'run' => {'mean' => ..., }, 'wait' => {'mean' => ..., }}


=head2 Time

It's important to note that Redis doesn't allow access to the system time if you're going to be making any manipulations to data (which our scripts do). And yet, we have heartbeating. This means that the clients actually send the current time when making most requests, and for consistency's sake, means that your workers must be relatively synchronized. This doesn't mean down to the tens of milliseconds, but if you're experiencing appreciable clock drift, you should investigate NTP. For what it's worth, this hasn't been a problem for us, but most of our jobs have heartbeat intervals of 30 minutes or more.

=head2 Ensuring Job Uniqueness

As mentioned above, Jobs are uniquely identied by an id--their jid. Qless will generate a UUID for each enqueued job or you can specify one manually:

    $queue->put('MyJobClass', { hello => 'howdy' }, jid => 'my-job-jid');

This can be useful when you want to ensure a job's uniqueness: simply create a jid that is a function of the Job's class and data, it'll guaranteed that Qless won't have multiple jobs with the same class and data.

=head2 Setting Default Job Options

=head2 Testing Jobs

=head1 DEVELOPMENT

=head2 Repository

qless-perl: L<https://bitbucket.org/nuclon/qless-perl|https://bitbucket.org/nuclon/qless-perl>

qless-core: L<https://github.com/seomoz/qless-core|https://github.com/seomoz/qless-core>

=head1 AUTHORS

qless, qless-py and qless-core - SEOmoz

qless-perl - Anatoliy Lapitskiy <nuclon@cpan.org>

=head1 COPYRIGHT & LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
