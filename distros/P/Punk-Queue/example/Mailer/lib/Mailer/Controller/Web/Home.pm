package Mailer::Controller::Web::Home;

use strict;
use warnings;
use parent 'Punk::Controller';
use File::Raw::JSON ();

# The web tier. Every handler here enqueues and answers; none of them waits
# for a task to run.

sub index {
    my ($c) = @_;
    return $c->render('index', {
        title  => 'Punk Mailer',
        csrf   => $c->csrf_field,
        stats  => $c->queue->stats,
        recent => $c->session->{recent} || [],
    });
}

# The point of the whole example: a request that would be slow if it did
# the work, and is not because it does not.
#
# $c->enqueue is the plugin's helper - a real method on this app's context
# class, installed at compile time. It returns the job id, which is enough
# to link to a page that watches it.
sub signup {
    my ($c) = @_;
    my $email = $c->param('email') // '';

    return $c->render('index', {
        title => 'Punk Mailer',
        csrf  => $c->csrf_field,
        error => 'that does not look like an email address',
        stats => $c->queue->stats,
    }) unless $email =~ /\A[^@\s]+\@[^@\s]+\z/;

    # unique: a second signup with the same address while one is still
    # queued or running returns the first job's id instead of enqueuing a
    # duplicate. The key obeys the same name rule as tasks and queues -
    # 1 to 64 characters of [A-Za-z0-9_.:-] - so an address has to be
    # folded into it rather than pasted in.
    (my $key = "welcome:" . lc $email) =~ s/[^A-Za-z0-9_.:-]/-/g;

    # The queue's defaults (attempts, timeout) come from the `queue 'mail'`
    # declaration in Mailer.pm; `delay` is this call's own.
    my $id = $c->enqueue('mail.welcome' => [$email],
                         delay  => 2,
                         unique => substr($key, 0, 64),
                         notes  => { source => 'signup form' });

    my $recent = $c->session->{recent} || [];
    unshift @$recent, { id => $id, email => $email };
    splice @$recent, 5 if @$recent > 5;
    $c->session->{recent} = $recent;

    return $c->redirect("/jobs/$id");
}

# The other half of "enqueue and answer": somewhere to look afterwards.
# $c->job is the plugin's helper for one job's row.
sub job {
    my ($c) = @_;
    my $id = $c->param('id');
    my $job = $id =~ /\A\d+\z/ ? $c->job($id) : undef;
    return $c->not_found unless $job;

    # result is whatever the task returned (or the die message on a
    # failure), decoded - so it needs re-encoding to show it as text.
    my $result = $job->{result};
    $result = File::Raw::JSON::file_json_encode($result) if ref $result;

    # retries is zero-based (the optimistic guard's raw value); people
    # count attempts from 1, and the job log's lifecycle rows already do
    return $c->render('job', {
        title   => "Job $id",
        job     => $job,
        attempt => $job->{retries} + 1,
        result  => $result,
        done    => ($job->{state} // '') =~ /\A(?:finished|failed)\z/ ? 1 : 0,
    });
}

# The coderef task, enqueued straight from the form on the index page -
# proof that a task body does not have to be a controller method to be a
# first-class job with retries, notes and a result.
sub ping {
    my ($c) = @_;
    my $id = $c->enqueue('ping' => [$c->param('note') // 'hello'],
                         priority => 10);
    return $c->redirect("/jobs/$id");
}

1;
