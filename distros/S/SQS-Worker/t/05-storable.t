#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use SQS::Worker::DefaultLogger;
use SQS::Worker::Client;
use Worker::Storable;
use TestMessage;


my $client = SQS::Worker::Client->new(serializer => 'storable', queue_url => '', region => '');
my $serialized = $client->serialize_params(1, 'param2', [1,2,3], { a => 'hash' });

my $worker = Worker::Storable->new(queue_url => '', region => '', log => SQS::Worker::DefaultLogger->new);

my $message = TestMessage->new(
  Body => $serialized,
  ReceiptHandle => ''
);
lives_ok { $worker->process_message($message) } 'expecting to live';

my $message_to_fail = TestMessage->new(
  Body => '',
  ReceiptHandle => ''
);
dies_ok { $worker->process_message($message_to_fail) } 'expecting to die';


done_testing();
