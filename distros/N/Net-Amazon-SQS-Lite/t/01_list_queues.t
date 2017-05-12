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

    is $res->{ResponseMetadata}->{RequestId}, '00000000-0000-0000-0000-000000000000';
    is %{$res->{ListQueuesResult}}, 0;
};

done_testing;
