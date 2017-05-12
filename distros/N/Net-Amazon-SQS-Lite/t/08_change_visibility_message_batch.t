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
    $sqs->send_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        MessageBody => "Hello!"
    });
    $res = $sqs->receive_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });
    $res = $sqs->change_message_visibility_batch({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "ChangeMessageVisibilityBatchRequestEntry.1.Id" => "change_visibility_msg_1",
        "ChangeMessageVisibilityBatchRequestEntry.1.ReceiptHandle" => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
        "ChangeMessageVisibilityBatchRequestEntry.1.VisibilityTimeout" => 60
    });
    is $res->{ResponseMetadata}->{RequestId}, "00000000-0000-0000-0000-000000000000";
    $sqs->delete_queue({QueueUrl => "http://localhost:9324/queue/test_queue"});
};

done_testing;
