use strict;
use Net::Amazon::SQS::Lite;
use Test::More 0.98;
use Time::Piece;
use Time::Seconds;
use URI;

my $sqs = Net::Amazon::SQS::Lite->new(
    access_key => "XXXXX",
    secret_key => "YYYYY",
    region => "ap-northeast-1",
    uri => URI->new("http://localhost:9324"),
);

SKIP: {
    my $res;
    eval {
        $res = $sqs->list_queues;
    };
    skip $@, 1 if $@;

    $sqs->create_queue({QueueName => "test_queue"});
    $res = $sqs->get_queue_url({
        QueueName => "test_queue",
    });
    is $res->{GetQueueUrlResult}->{QueueUrl}, "http://localhost:9324/queue/test_queue";
    $sqs->delete_queue({QueueUrl => "http://localhost:9324/queue/test_queue"});
};

done_testing;
