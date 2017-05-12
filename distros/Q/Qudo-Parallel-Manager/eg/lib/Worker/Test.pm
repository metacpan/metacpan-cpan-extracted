package Worker::Test;
use strict;
use warnings;
use base 'Qudo::Worker';
sub work {
    my ($class, $job) = @_;
    srand(time ^ ($$ + ($$ << 15)));
    sleep(int(rand(30)));
#    sleep(20);
    $job->completed;
}
1;
