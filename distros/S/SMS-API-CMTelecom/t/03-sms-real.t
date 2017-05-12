#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use SMS::API::CMTelecom;


# These tests can only be executed with a correct product token and a correct phone number.
# Please provide them by setting the environment variables
# SMS_CMTELECOM_PRODUCT_TOKEN and SMS_CMTELECOM_PHONE_NUMBER
#
# Currently, two SMS messages are sent out and they will be billed to your account.

if (!$ENV{SMS_CMTELECOM_PRODUCT_TOKEN} or !$ENV{SMS_CMTELECOM_PHONE_NUMBER}) {
    plan skip_all => 'Please provide environment variables SMS_CMTELECOM_PRODUCT_TOKEN and SMS_CMTELECOM_PHONE_NUMBER for this test to run. It will send two messages you have to pay for.';
    exit;
}

plan tests => 2;

my $product_token = $ENV{SMS_CMTELECOM_PRODUCT_TOKEN};
my $phone_number  = $ENV{SMS_CMTELECOM_PHONE_NUMBER};

subtest simple_message => sub {
    plan tests => 4;
    my $sms = SMS::API::CMTelecom->new(
        product_token => $product_token,
        sender        => $phone_number,
    );

    is ref $sms, 'SMS::API::CMTelecom', 'SMS object created';
    
    my $res = $sms->send(
        message    => 'This is a test of the Perl module SMS::API::CMTelecom :-)',
        recipients => $phone_number,
    );

    is ref $res, 'HASH', 'message sent';
    is_deeply $res, {
            messages => [
                {
                    to             => clean_number($phone_number),
                    parts          => 1,
                    reference      => undef,
                    messageDetails => undef,
                    status         => 'Accepted',
                },
            ],
        }, 'correct status information';
    is $sms->error_message, undef, 'error message is empty';
};

subtest simple_message_with_reference => sub {
    plan tests => 4;
    my $sms = SMS::API::CMTelecom->new(
        product_token => $product_token,
        sender        => $phone_number,
    );

    is ref $sms, 'SMS::API::CMTelecom', 'SMS object created';
    my @chars = (0..9, 'A'..'Z', 'a'..'z');
    my $reference = join "" => map { $chars[int rand @chars] } 1..(1+int(rand 32));
    
    my $res = $sms->send(
        message    => 'This is a test of the Perl module SMS::API::CMTelecom :-)',
        recipients => $phone_number,
        reference  => $reference,
    );

    is ref $res, 'HASH', 'message sent';
    is_deeply $res, {
            messages => [
                {
                    to             => clean_number($phone_number),
                    parts          => 1,
                    reference      => $reference,
                    messageDetails => undef,
                    status         => 'Accepted',
                },
            ],
        }, "correct status information with included reference ($reference)";
    is $sms->error_message, undef, 'error message is empty';
};

sub clean_number {
    my $num = shift;
    $num =~ s/\D//g;
    return $num;
}