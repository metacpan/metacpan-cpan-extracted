#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use SQS::Worker::DefaultLogger;

use SQS::Worker::Client;
use Worker::SNS;
use TestMessage;

{
  my $worker = Worker::SNS->new(queue_url => '', region => '', log => SQS::Worker::DefaultLogger->new);
  my $serialized = '{
  "Type" : "Notification",
  "MessageId" : "00000000-0000-0000-0000-000000000000",
  "TopicArn" : "arn:aws:sns:eu-west-1:000000000000:MyStack-VXW54P0JXJO3",
  "Subject" : "AWS CloudFormation Notification",
  "Message" : "StackId=\'arn:aws:cloudformation:eu-west-1:000000000000:stack/MyStack/00000000-0000-0000-0000-000000000000\'\\nTimestamp=\'2016-02-18T10:55:09.151Z\'\\nEventId=\'User-DELETE_IN_PROGRESS-2016-02-18T10:55:09.151Z\'\\nLogicalResourceId=\'User\'\\nNamespace=\'000000000000\'\\nPhysicalResourceId=\'MyStack-User-KKZ5JSEG0VVY\'\\nResourceProperties=\'{\\"Path\\":\\"/1/\\"}\\n\'\\nResourceStatus=\'DELETE_IN_PROGRESS\'\\nResourceStatusReason=\'\'\\nResourceType=\'AWS::IAM::User\'\\nStackName=\'MyStack\'\\n",
  "Timestamp" : "2016-02-18T10:55:09.440Z",
  "SignatureVersion" : "1",
  "Signature" : "XXXXXXX",
  "SigningCertURL" : "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-00000000000000000000000000000000.pem",
  "UnsubscribeURL" : "https://sns.eu-west-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-1:000000000000:MyStack-VXW54P0JXJO3:00000000-0000-0000-0000-000000000000"
}';
  my $message = TestMessage->new(
    Body => $serialized,
    ReceiptHandle => ''
  );
  lives_ok { $worker->process_message($message) } 'expecting to live';

  my $message_to_fail = TestMessage->new(
    Body => '{}',
    ReceiptHandle => ''
  );
  dies_ok { $worker->process_message($message_to_fail) } 'expecting to die';
}

done_testing();
