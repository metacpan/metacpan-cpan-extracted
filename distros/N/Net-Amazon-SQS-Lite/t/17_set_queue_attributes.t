use strict;
use Net::Amazon::SQS::Lite;
use Test::More 0.98;
use Time::Piece;
use Time::Seconds;
use URI;

# Queue attributes weren't changed of ElasticMQ
ok 1;

#my $sqs = Net::Amazon::SQS::Lite->new(
#    access_key => "XXXXX",
#    secret_key => "YYYYY",
#    region => "ap-northeast-1",
#    uri => URI->new("http://localhost:9324"),
#);
# 
#SKIP: {
#    my $res;
#    eval {
#        $res = $sqs->list_queues;
#    };
#    skip $@, 1 if $@;
# 
#    $sqs->create_queue({QueueName => "test_queue"});
#    $sqs->set_queue_attributes({
#        QueueUrl => "http://localhost:9324/queue/test_queue",
#        "Attribute.Name" => "VisibilityTimeout",
#        "Attribute.Value" => 40,
#    });
#    $res = $sqs->get_queue_attributes({
#        QueueUrl => "http://localhost:9324/queue/test_queue",
#        "AttributeName.1" => "VisibilityTimeout",
#    });
#    is $res->{GetQueueAttributesResult}->{Attribute}->{Name}, "VisibilityTimeout";
#    is $res->{GetQueueAttributesResult}->{Attribute}->{Value}, 40;
#    $sqs->delete_queue({QueueUrl => "http://localhost:9324/queue/test_queue"});
#};

done_testing;
