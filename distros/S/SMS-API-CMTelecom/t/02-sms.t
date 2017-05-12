#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use SMS::API::CMTelecom;

plan tests => 4;

subtest no_product_token => sub {
    plan tests => 2;
    
    my $sms = eval { SMS::API::CMTelecom->new() };
    like $@, qr'^SMS::API::CMTelecom->new requires product_token parameter', 'correct error message';
    ok !$sms, 'creating SMS object failed';
};

subtest simple_object_creation => sub {
    plan tests => 2;
    my $sms = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    is ref $sms, 'SMS::API::CMTelecom', 'SMS object created';
    
    subtest no_sender_given => sub {
        plan tests => 2;

        my $res = $sms->send(
            message    => 'please call me!',
            recipients => '00490000000000000',
        );

        is $res, undef, 'undef returned';
        is $sms->error_message, 'SMS::API::CMTelecom->send requires a sender number', 'correct error message';
    };
};

subtest wrong_recipients => sub {
    plan tests => 10;

    my $sms = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res = $sms->send(
        sender     => '054684980651',
        message    => 'please call me!',
        recipients => [],
        reference  => 293854,
    );
    is $res, undef, 'undef returned';
    is $sms->error_message, 'SMS::API::CMTelecom->send requires at least one recipient number', 'correct error message';

    my $sms2 = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res2 = $sms2->send(
        sender     => '054684980651',
        message    => 'please call me!',
        reference  => 293854,
    );
    is $res2, undef, 'undef returned';
    is $sms2->error_message, 'SMS::API::CMTelecom->send requires at least one recipient number', 'correct error message';

    my $sms3 = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res3 = $sms3->send(
        sender     => '054684980651',
        message    => 'please call me!',
        recipients => { number => '004133105465464' },
        reference  => 293854,
    );
    is $res3, undef, 'undef returned';
    is $sms3->error_message, 'recipient must be a telephone number', 'correct error message';

    my $sms4 = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res4 = $sms4->send(
        sender     => '054684980651',
        message    => 'please call me!',
        recipients => [ '56404650', '', 12354 ],
        reference  => 293854,
    );
    is $res4, undef, 'undef returned';
    is $sms4->error_message, 'recipient may not be an empty string', 'correct error message';

    my $sms5 = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res5 = $sms5->send(
        sender     => '054684980651',
        message    => 'please call me!',
        recipients => [ 'number', '004133105465464', undef ],
        reference  => 293854,
    );
    is $res5, undef, 'undef returned';
    is $sms5->error_message, 'recipient may not be undefined', 'correct error message';
};

subtest wrong_product_token => sub {
    plan tests => 2;

    my $sms = SMS::API::CMTelecom->new(
        product_token => '00000000-0000-0000-0000-000000000000',
    );

    my $res = $sms->send(
        sender     => '054684980651',
        message    => 'please call me!',
        recipients => '0049000000',
        reference  => 293854,
    );
    is $res, undef, 'undef returned';
    is $sms->error_message, 'No account found for the given authentication', 'correct error message';
};
