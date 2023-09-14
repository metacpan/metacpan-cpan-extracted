use Test::More;

use utf8;
use strict;
use warnings;

require_ok 'Pass::OTP';

# Based on the test vectors from RFC6238

my %seeds = (
    sha1   => '3132333435363738393031323334353637383930',
    sha256 => '3132333435363738393031323334353637383930'.
              '313233343536373839303132',
    sha512 => '3132333435363738393031323334353637383930'.
              '3132333435363738393031323334353637383930'.
              '3132333435363738393031323334353637383930'.
              '31323334',
);

sub is_totp {
    my %opts = (@_);

    is(
        Pass::OTP::otp(
        secret    => $seeds{$opts{algorithm}},
        algorithm => $opts{algorithm},
        now       => $opts{now},
        digits    => 8,
        type      => 'totp'),
        $opts{totp},
        "Test vector with time (sec) $opts{now} on mode $opts{algorithm}"
    );
}

is_totp(now => 59, algorithm => 'sha1',   totp => '94287082');
is_totp(now => 59, algorithm => 'sha256', totp => '46119246');
is_totp(now => 59, algorithm => 'sha512', totp => '90693936');


is_totp(now => 1111111109, algorithm => 'sha1',   totp => '07081804');
is_totp(now => 1111111109, algorithm => 'sha256', totp => '68084774');
is_totp(now => 1111111109, algorithm => 'sha512', totp => '25091201');


is_totp(now => 1111111111, algorithm => 'sha1',   totp => '14050471');
is_totp(now => 1111111111, algorithm => 'sha256', totp => '67062674');
is_totp(now => 1111111111, algorithm => 'sha512', totp => '99943326');


is_totp(now => 1234567890, algorithm => 'sha1',   totp => '89005924');
is_totp(now => 1234567890, algorithm => 'sha256', totp => '91819424');
is_totp(now => 1234567890, algorithm => 'sha512', totp => '93441116');


is_totp(now => 2000000000, algorithm => 'sha1',   totp => '69279037');
is_totp(now => 2000000000, algorithm => 'sha256', totp => '90698825');
is_totp(now => 2000000000, algorithm => 'sha512', totp => '38618901');


is_totp(now => 20000000000, algorithm => 'sha1',   totp => '65353130');
is_totp(now => 20000000000, algorithm => 'sha256', totp => '77737706');
is_totp(now => 20000000000, algorithm => 'sha512', totp => '47863826');


done_testing(19);
