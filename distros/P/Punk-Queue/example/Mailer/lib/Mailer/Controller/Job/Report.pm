package Mailer::Controller::Job::Report;

use strict;
use warnings;

# The other task target. This one shows the two things a recurring job
# usually needs: a lock, so overlapping runs cannot both do the work, and a
# result worth reading afterwards.

sub signups {
    my ($job) = @_;
    my $q = $job->queue_object;

    # Named locks live in the database with the jobs, so this holds across
    # every worker on every host - not just this process. Taking it with a
    # duration means a crashed holder releases itself.
    my $lock = $q->lock('report.signups', 60)
        or return { skipped => 'another worker holds the lock' };

    my $stats = $q->stats;
    $job->note(counted_at => time);

    $q->unlock('report.signups');

    return {
        inactive => $stats->{inactive_jobs},
        active   => $stats->{active_jobs},
        finished => $stats->{finished_jobs},
        failed   => $stats->{failed_jobs},
    };
}

1;
