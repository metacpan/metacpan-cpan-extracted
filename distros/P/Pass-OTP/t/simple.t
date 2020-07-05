use Test::More;

use utf8;
use strict;
use warnings;

require_ok 'Pass::OTP';
require_ok 'Pass::OTP::URI';

is(
    Pass::OTP::otp(
        secret => "00",
    ),
    '328482',
    'oathtool 00',
);

is(
    Pass::OTP::otp(
        secret => "00",
        counter => 100,
    ),
    '032003',
    'oathtool -c 100 00',
);

is(
    Pass::OTP::otp(
        Pass::OTP::URI::parse('otpauth://hotp/Test?secret=abcdefgh')
    ),
    '058591',
    'otptool otpauth://hotp/Test?secret=abcdefgh',
);

is(
    Pass::OTP::otp(
        Pass::OTP::URI::parse('otpauth://totp/Test?secret=abcdefgh&issuer=Steam&now=1')
    ),
    'KMP7M',
    'otptool otpauth://totp/Test?secret=abcdefgh&issuer=Steam',
);

done_testing(6);
