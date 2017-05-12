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
    $res = $sqs->send_message_batch({
        "SendMessageBatchRequestEntry.1.Id" => "msg1",
        "SendMessageBatchRequestEntry.1.MessageBody" => "Hello!",
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });
    is $res->{SendMessageBatchResult}->{SendMessageBatchResultEntry}->{MD5OfMessageBody}, "952d2c56d0485958336747bcdd98590d";
    $res = $sqs->delete_queue({QueueUrl => "http://localhost:9324/queue/test_queue"});
};

done_testing;
