use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok( 'SMS::Send' );
    use_ok( 'SMS::Send::AT::TMobile' );
}

throws_ok sub { my $sender = SMS::Send->new('AT::TMobile') },
    qr/_login missing/,
    'sender construction without _login and _password throws exception';

throws_ok sub { my $sender = SMS::Send->new('AT::TMobile',
    _login => 'foo' ) },
    qr/_password missing/,
    'sender construction without _password throws exception';

throws_ok sub { my $sender = SMS::Send->new('AT::TMobile',
    _password => 'foo' ) },
    qr/_login missing/,
    'sender construction without _login throws exception';

ok(
    my $sender = SMS::Send->new('AT::TMobile',
        _login    => 'foo',
        _password => 'bar',
    ), 'sender construction ok'
);

throws_ok sub {
        $sender->send_sms(
            text => 'This is a test message',
            to   => 436761234567,
        );
    },
    qr/_from missing/,
    'send_sms without _from throws exception';

done_testing;
