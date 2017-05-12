use Test::More tests => 4;

BEGIN {
    use_ok( 'SMS::Send' );
    use_ok( 'SMS::Send::AT::SmsAt' );
}

SKIP: {
    skip 'Set SMS_SEND_LOGIN SMS_SEND_PASSWORD and SMS_SEND_RECIPIENT to test sending SMS', 2 unless $ENV{SMS_SEND_LOGIN} and $ENV{SMS_SEND_PASSWORD} and $ENV{SMS_SEND_RECIPIENT};

# Create a sender
    ok(my $sender = SMS::Send->new('AT::SmsAt',
        _login    => $ENV{SMS_SEND_LOGIN},
        _password => $ENV{SMS_SEND_PASSWORD},
    ));

# Send a message
    ok(my $sent = $sender->send_sms(
        text => 'This is a test message',
        to   => $ENV{SMS_SEND_RECIPIENT},
    ) == 1);
}
