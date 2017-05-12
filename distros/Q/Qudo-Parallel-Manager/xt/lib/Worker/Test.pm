package Worker::Test;
use strict;
use warnings;
use base 'Qudo::Worker';

sub work {
    my ($class, $job) = @_;
    $job->completed;
}
1;
