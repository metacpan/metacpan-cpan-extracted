#!/usr/bin/env perl

use lib 't/fake-sqs-lib/';
use lib 't/lib/';

use Test::More;
use Test::Exception;

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
      caller_for => {
        SQS => CounterCaller->new
      }
    )
  }
);

my $sqs = $paws1->service('SQS', region => 'test');
my $result;
lives_ok(sub {
  $result = $sqs->CreateQueue(QueueName => 'qname');
}, 'SQS is auto-loaded');

cmp_ok($sqs->caller->caller_for->{SQS}->called_me_times, '==', 1, 'Called SQS one time');

my $ec2 = $paws1->service('EC2', region => 'test');
throws_ok(sub {
  $result = $ec2->AllocateAddress;
}, qr/^Can't find a caller for EC2/, "Call to AllocateAddress on EC2 dies (no default caller)");

done_testing;
