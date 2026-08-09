package Mailer::Controller::Job::Mail;

use strict;
use warnings;

# Task bodies, not request handlers - so no Punk::Controller and no $c.
#
# A body is called with the Punk::Queue::Job first and the enqueued
# arguments after; there is no invocant, because the plugin resolves
# 'Job::Mail#welcome' to this sub and hands it to the queue as a body.
#
# Two rules the queue cannot enforce for you:
#
#   * Be idempotent. A worker killed past its timeout may have done part of
#     the work already, and the retry runs the whole body again.
#   * Die loudly on failure. The die message is what lands in the job's
#     result and what the admin UI shows; a body that swallows an error and
#     returns is a job that succeeded.

sub welcome {
    my ($job, $email) = @_;

    die "welcome mail with no address\n" unless defined $email && length $email;

    # Where a real app would hand off to its MTA. The sleep stands in for
    # the network call that made this worth queueing in the first place.
    sleep 1;
    _deliver($email, 'Welcome to Punk Mailer',
             "Thanks for signing up.\n");

    # Notes are for the operator: they ride on the job row and show up in
    # the admin UI and `punk-queue job ID`.
    $job->note(delivered_to => $email);

    # The return value becomes the job's result.
    return { to => $email, template => 'welcome' };
}

# The cron target. It runs on a schedule, so it takes no request-shaped
# arguments - only what the cron declaration passes.
sub digest {
    my ($job, $window) = @_;
    $window ||= 'daily';

    my @recipients = _subscribers($window);

    # Fanning out is a job enqueueing jobs: one row each, so one failure
    # retries alone instead of taking the batch with it.
    my $q = $job->queue_object;
    my @ids = map {
        $q->enqueue('mail.welcome' => [$_], queue => 'mail', priority => -5)
    } @recipients;

    return { window => $window, fanned_out => scalar @ids };
}

sub _deliver {
    my ($to, $subject, $body) = @_;
    # An example does not send mail. Print it where the worker's log goes.
    print STDERR "[mail] to=$to subject=$subject\n";
    return 1;
}

sub _subscribers {
    my ($window) = @_;
    return map { "subscriber-$_\@example.com" } 1 .. 3;
}

1;
