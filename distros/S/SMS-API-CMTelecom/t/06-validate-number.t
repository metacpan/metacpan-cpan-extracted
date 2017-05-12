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
    plan skip_all => 'Please provide environment variables SMS_CMTELECOM_PRODUCT_TOKEN and SMS_CMTELECOM_PHONE_NUMBER for this test to run.';
    exit;
}

plan tests => 5;

my $product_token        = $ENV{SMS_CMTELECOM_PRODUCT_TOKEN};
my $phone_number         = $ENV{SMS_CMTELECOM_PHONE_NUMBER};

my $sms = SMS::API::CMTelecom->new(
    product_token => $product_token,
);

is ref $sms, 'SMS::API::CMTelecom', 'SMS object created';

is $sms->validate_number($phone_number), 1, 'validated successfully';

my $number_details = $sms->number_details($phone_number);

is ref $number_details, 'HASH', 'number details is a hash reference';

subtest response_content => sub {
    my @keys = qw/region carrier region_code type country_iso ported timezone format_international ported country_code format_national format_e164/;

    plan tests => scalar @keys;

    for my $key (@keys) {
        ok exists $number_details->{$key}, "key $key exists";
    }

    diag "number was ".($number_details->{ported} ? '': 'not ')."ported.";
};


subtest invalid_phone_number => sub {
    my $invalid_phone_number = $ENV{SMS_CMTELECOM_INVALID_PHONE_NUMBER};
    if (!$invalid_phone_number) {
        plan skip_all => 'Please provide environment variables SMS_CMTELECOM_PRODUCT_TOKEN and SMS_CMTELECOM_INVALID_PHONE_NUMBER for this test to run.';
        return;
    }

    plan tests => 1;

    is $sms->validate_number($invalid_phone_number), 0, 'successfully stated that number is not valid';
}
