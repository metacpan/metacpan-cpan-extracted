package Worker::NothingWorker;
use Moose;
with 'SQS::Worker', 'SQS::Worker::DecodeJson';
sub process_message {
    print STDERR "\n\nOH NO!\n\n";
    die "never reach that point";
}

1;
