#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use SMS::Send;

plan tests => 3;

# create the sender object
my $sender = SMS::Send::->new('CMTelecom',
    _producttoken => '123',
);

is ref $sender, 'SMS::Send', 'SMS::Send object created';

# send a message
my $sent = $sender->send_sms(
    text    => 'You message may use more than 160 chars.',
    to      => '+49 555 4444',
    _reference => 709090912384,
);

is $sent, 0, 'message without sender not sent';

subtest send_real => sub {
    if (!$ENV{SMS_CMTELECOM_PRODUCT_TOKEN} or !$ENV{SMS_CMTELECOM_PHONE_NUMBER}) {
        plan skip_all => 'Please provide environment variables SMS_CMTELECOM_PRODUCT_TOKEN and SMS_CMTELECOM_PHONE_NUMBER for this test to run. It will send two messages you have to pay for.';
        return;
    }

    plan tests => 2;

    my $real_sender = SMS::Send::->new('CMTelecom',
        _producttoken => $ENV{SMS_CMTELECOM_PRODUCT_TOKEN},
    );

    is ref $real_sender, 'SMS::Send', 'SMS::Send object created';

    my $sent = $real_sender->send_sms(
        text       => 'You message may use more than 160 chars.',
        to         => $ENV{SMS_CMTELECOM_PHONE_NUMBER},
        _from      => $ENV{SMS_CMTELECOM_PHONE_NUMBER},
        reference  => 'SMS::Send::CMTelecom test',
    );

    is $sent, 1, 'message successfully sent';

};
