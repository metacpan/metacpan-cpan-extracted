#!/usr/bin/env perl

use lib 't/fake-sqs-lib/';
use lib 't/fake-ec2-lib/';
use lib 't/lib/';

use Test::More tests => 1;

use Paws;
use CounterCaller;
use Paws::Net::MultiplexCaller;
use Paws::Credential::Explicit;

my $paws1 = Paws->new(
  config => {
    credentials => Paws::Credential::Explicit->new(
      access_key => '-',
      secret_key => '-',
    ),
    caller => Paws::Net::MultiplexCaller->new(
      caller_for => { },
      default_caller => CounterCaller->new 
    )
  }
);

my $sqs = $paws1->service('SQS', region => 'test');
my $result = $sqs->CreateQueue(QueueName => 'qname');

cmp_ok($sqs->caller->default_caller->called_me_times, '==', 1, 'Called SQS one time');

done_testing;
