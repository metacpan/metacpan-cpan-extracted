use strict;
use warnings;
use Test::More;
use Test::Exception;
use SMS::Send;

unless (   defined $ENV{SMS_Send_Retarus_login}
        && defined $ENV{SMS_Send_Retarus_password}
        && defined $ENV{SMS_Send_Retarus_to} ) {
    plan skip_all =>
        "tests can't be run without SMS_Send_Retarus_login, _password and _to environment variables";
}

my $invalid_sender = SMS::Send->new('Retarus',
    _login    => 'SMS::Send::Retarus test user',
    _password => 'invalid password',
);


throws_ok {
    $invalid_sender->send_sms(
        to      => $ENV{SMS_Send_Retarus_to},
        text    => 'Test message',
    ) }
    'SMS::Send::Retarus::Exception',
    'throws a SMS::Send::Retarus::Exception when credentials are incorrect';

like $@, qr/^Credentials are required to access this resource/,
    'exception text ok';

my $sender = SMS::Send->new('Retarus',
    _login    => $ENV{SMS_Send_Retarus_login},
    _password => $ENV{SMS_Send_Retarus_password},
);


throws_ok {
    $sender->send_sms(
        to      => $ENV{SMS_Send_Retarus_to},
        text    => 'Test message',
        _options => {
            src  => 'TooLongTextsender', # max is 11 characters
        }
    ) }
    'SMS::Send::Retarus::Exception',
    'throws a SMS::Send::Retarus::Exception when src option is too long';

like $@, qr/options\.src must match/,
    'exception text ok';

is ref $@->response, 'HASH',
    'SMS::Send::Retarus::Exception response field is a hashref';


throws_ok {
    $sender->send_sms(
        to      => $ENV{SMS_Send_Retarus_to},
        text    => 'Test message',
        _options => {
            qos  => 'invalid',
        }
    ) }
    'SMS::Send::Retarus::Exception',
    'throws a SMS::Send::Retarus::Exception when qos option is invalid';

like $@, qr/Wrong qos: invalid/,
    'exception text ok';

is ref $@->response, 'HASH',
    'SMS::Send::Retarus::Exception response field is a hashref';

lives_and { ok $sender->send_sms(
    to      => $ENV{SMS_Send_Retarus_to},
    text    => 'Test message without specified sender',
) } 'send_sms returns true with the minimum required parameters';

lives_and { ok $sender->send_sms(
    to      => $ENV{SMS_Send_Retarus_to},
    text    => 'Test message with text sender',
    _options => {
        src  => 'Textsender',
    }
) } 'send_sms returns true with text sender';

done_testing;
