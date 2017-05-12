#!/usr/bin/env perl
use Test::Most;
use Net::Amazon::SNS::Signature;

# Test that signature composition is as detailed in below URL
# http://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.verify.signature.html

is_deeply ( [ Net::Amazon::SNS::Signature->_signature_keys({ Type => 'Notification' }) ], [ qw/Message MessageId Timestamp TopicArn Type/ ] );
is_deeply ( [ Net::Amazon::SNS::Signature->_signature_keys({ Type => 'Madeup' }) ], [ qw/Message MessageId Timestamp TopicArn Type/ ] );
is_deeply ( [ Net::Amazon::SNS::Signature->_signature_keys({ Type => 'Notification', Subject => 'test'}) ], [ qw/Message MessageId Subject Timestamp TopicArn Type/ ] );
is_deeply ( [ Net::Amazon::SNS::Signature->_signature_keys({ Type => 'UnsubscribeConfirmation' }) ], [ qw/Message MessageId SubscribeURL Timestamp Token TopicArn Type/ ] );
is_deeply ( [ Net::Amazon::SNS::Signature->_signature_keys({ Type => 'SubscriptionConfirmation' }) ], [ qw/Message MessageId SubscribeURL Timestamp Token TopicArn Type/ ] );

done_testing();
