use Test::More;

use utf8;
use strict;
use warnings;

use open qw(:std :utf8);

my $oathtool = '/usr/bin/oathtool';

sub t {
    my ($cmd, %args) = @_;

    my $ret = qx($cmd);
    chomp($ret);
    my $code = Pass::OTP::otp(%args);
    return is($code, $ret, $cmd);
}

if (not -x $oathtool or system("$oathtool -w1 00")) {
    plan skip_all => 'oathtool not installed';
}

require_ok 'Pass::OTP';

t(
    'oathtool 00',
    secret => "00",
);

TODO: {
    local $TODO = "Parameter --window not implemented";
    t(
        "$oathtool -w 10 3132333435363738393031323334353637383930",
        secret => "3132333435363738393031323334353637383930",
        window => 10,
    );

    t(
        "$oathtool --base32 -w 3 GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
        secret => "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
        base32 => 1,
        window => 3,
    );
}

t(
    "$oathtool --base32 --totp 'gr6d 5br7 25s6 vnck v4vl hlao re'",
    secret => "gr6d 5br7 25s6 vnck v4vl hlao re",
    base32 => 1,
    type   => 'totp',
);

t(
    "$oathtool -c 5 3132333435363738393031323334353637383930",
    secret  => "3132333435363738393031323334353637383930",
    counter => 5,
);

t(
    "$oathtool -b --totp --now '2008-04-23 17:42:17 UTC' IFAUCQIK",
    secret => "IFAUCQIK",
    base32 => 1,
    type   => 'totp',
    now    => `date -d'2008-04-23 17:42:17 UTC' +%s`,
);

t(
    "$oathtool --totp --now '2008-04-23 17:42:17 UTC' 00",
    secret => "00",
    type   => 'totp',
    now    => `date -d'2008-04-23 17:42:17 UTC' +%s`,
);

t(
    "$oathtool --totp 00",
    secret => "00",
    type   => 'totp',
);

t(
"$oathtool --totp --digits=8 --now '2009-02-13 23:31:30 UTC' 3132333435363738393031323334353637383930313233343536373839303132",
    secret => "3132333435363738393031323334353637383930313233343536373839303132",
    type   => 'totp',
    digits => 8,
    now    => `date -d'2009-02-13 23:31:30 UTC' +%s`
);

t(
"$oathtool --totp=sha256 --digits=8 --now '2009-02-13 23:31:30 UTC' 3132333435363738393031323334353637383930313233343536373839303132",
    secret    => "3132333435363738393031323334353637383930313233343536373839303132",
    type      => 'totp',
    algorithm => 'sha256',
    digits    => 8,
    now       => `date -d'2009-02-13 23:31:30 UTC' +%s`,
);

t(
"$oathtool --totp=sha512 --digits=8 --now '2009-02-13 23:31:30 UTC' 3132333435363738393031323334353637383930313233343536373839303132",
    secret    => "3132333435363738393031323334353637383930313233343536373839303132",
    type      => 'totp',
    algorithm => 'sha512',
    digits    => 8,
    now       => `date -d'2009-02-13 23:31:30 UTC' +%s`,
);

TODO: {
    local $TODO = "Parameter --window not implemented";
    t(
        "$oathtool --totp 00 -w5",
        secret => "00",
        type   => 'totp',
        window => 5,
    );
}

TODO: {
    local $TODO = "Parameter --verbose not implemented";
    t(
        "$oathtool --totp -v -N '2033-05-18 03:33:20 UTC' -d8 3132333435363738393031323334353637383930",
        secret  => "3132333435363738393031323334353637383930",
        type    => 'totp',
        verbose => 1,
        now     => `date -d'2033-05-18 03:33:20 UTC' +%s`,
        digits  => 8,
    );
}

done_testing(14);
