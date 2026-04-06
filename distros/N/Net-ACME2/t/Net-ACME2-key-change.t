#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use Digest::MD5;
use HTTP::Status;
use URI;
use JSON;
use MIME::Base64 ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;
use Test::Crypt;

#----------------------------------------------------------------------

{
    package MyCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

my $_RSA_KEY = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCkOYWppsEFfKHqIntkpUjmuwnBH3sRYP00YRdIhrz6ypRpxX6H
c2Q0IrSprutu9/dUy0j9a96q3kRa9Qxsa7paQj7xtlTWx9qMHvhlrG3eLMIjXT0J
4+MSCw5LwViZenh0obBWcBbnNYNLaZ9o31DopeKcYOZBMogF6YqHdpIsFQIDAQAB
AoGAN7RjSFaN5qSN73Ne05bVEZ6kAmQBRLXXbWr5kNpTQ+ZvTSl2b8+OT7jt+xig
N3XY6WRDD+MFFoRqP0gbvLMV9HiZ4tJ/gTGOHesgyeemY/CBLRjP0mvHOpgADQuA
+VBZmWpiMRN8tu6xHzKwAxIAfXewpn764v6aXShqbQEGSEkCQQDSh9lbnpB/R9+N
psqL2+gyn/7bL1+A4MJwiPqjdK3J/Fhk1Yo/UC1266MzpKoK9r7MrnGc0XjvRpMp
JX8f4MTbAkEAx7FvmEuvsD9li7ylgnPW/SNAswI6P7SBOShHYR7NzT2+FVYd6VtM
vb1WrhO85QhKgXNjOLLxYW9Uo8s1fNGtzwJAbwK9BQeGT+cZJPsm4DpzpIYi/3Zq
WG2reWVxK9Fxdgk+nuTOgfYIEyXLJ4cTNrbHAuyU8ciuiRTgshiYgLmncwJAETZx
KQ51EVsVlKrpFUqI4H72Z7esb6tObC/Vn0B5etR0mwA2SdQN1FkKrKyU3qUNTwU0
K0H5Xm2rPQcaEC0+rwJAEuvRdNQuB9+vzOW4zVig6HS38bHyJ+qLkQCDWbbwrNlj
vcVkUrsg027gA5jRttaXMk8x9shFuHB9V5/pkBFwag==
-----END RSA PRIVATE KEY-----
END

my $_NEW_RSA_KEY = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgGp9aoiOu1Q1BI75pAyE2ctK3gYuZuIX+0VAh5msQ4WaHpVd0fzM
xtrVbb+ZV1dK4Bhqv0mshxSYF6iQKEMuuolG7NmnxuFFhSa7KLrr2zyNDluQ/jN3
sMt/9EjvQqgkAOHLTAZq8lIj/MYTmCctKOCLO+PXHoW564AOiti9vKwrAgMBAAEC
gYBDPumMTF29QjGbu8c9ZJNIDgIAc0Li2XQB+krm3uJQts9DUViuQ/366LYCPOnr
pMu4f4hGFN3EQnsGJepW6mY+Qsia4qYMbF7zgsz8wdApfmecny5uVeKSlYf0lkFH
vjgFpHCmlt5zMgbFWFhKmG6lYn/xKBloR5ZDqx/Sz8RQ6QJBALLsaIygsmZh2Uxv
5gAHUQMo/TSKAIQbjSXq9Wky4jmnagD0i1o78+ZR9Ze/07TJRU9z8AeXaJGCSq32
3Qmhdt0CQQCYXRH9yqtwYn3GtLohtO70tkUGe6yq99+dg6AT+jjDrvNZZjcUd4g+
7epze+qg5sSBHz4YiqscKOFwhA+y2YqnAkEAoYLEEYWR5NeZBuXPseDo4Thj8MRO
GPKh5EOHSnITQkX8a2ZUUJzj2tnLHzObEIvLFCCs4L1tOERr00OPXf0xxQJABtLM
Nnh4Gw1eIqL/XvkSZoUvLC4nunRlYFF/vsVK+4B/R3aratA7ms3e3RMkm9YZ4Mp8
Zm73YMh36CkR5umVKwJAYJl5i1We0z04dkOV5R3mXVi31c0uddwkAizEvRkkEmvz
xXhVMA+tVVaBXItzwjkCT6BreDIbmhQJQo1B5ePPpA==
-----END RSA PRIVATE KEY-----
END

my $_P256_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKDv8TBijBVbTYB7lfUnwLn4qjqWD0GD7XOXzdp0wb61oAoGCCqGSM49
AwEHoUQDQgAEBJIULcFadtIBc0TuNzT80UFcfkQ0U7+EPqEJNXamG1H4/z8xVgE7
3hoBfX4xbN2Hx2p26eNIptt+1jj2H/M44g==
-----END EC PRIVATE KEY-----
END

my $_NEW_P256_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIA/91GJTtitXV+PvZVfLxc7XsdeO8PXte4O7+oWFnyrZoAoGCCqGSM49
AwEHoUQDQgAEZEFmmS27sg0wCXQWyk/7L/Ou2klAOvhWgcF4E8fcl8m+v5HeGlJA
z7FzdwKfHyBHcLvYvws8L6PO4W+LuHS4fQ==
-----END EC PRIVATE KEY-----
END

my @test_cases = (
    [ 'RSA to RSA', $_RSA_KEY, $_NEW_RSA_KEY ],
    [ 'P-256 to P-256', $_P256_KEY, $_NEW_P256_KEY ],
    [ 'RSA to P-256', $_RSA_KEY, $_NEW_P256_KEY ],
    [ 'P-256 to RSA', $_P256_KEY, $_NEW_RSA_KEY ],
);

for my $tc (@test_cases) {
    my ($label, $old_key, $new_key) = @$tc;

    subtest "change_key - $label" => sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyCA',
            enable_key_change => 1,
        );

        my $acme = MyCA->new( key => $old_key );

        $acme->create_account(
            termsOfServiceAgreed => 1,
        );

        my $old_key_id = $acme->key_id();
        ok( $old_key_id, 'have key_id before change_key' );

        lives_ok(
            sub { $acme->change_key($new_key) },
            'change_key() succeeds',
        );

        is( $acme->key_id(), $old_key_id, 'key_id unchanged after rollover' );

        # Verify the inner JWS was properly constructed by checking
        # the server recorded it
        my $last_key_change = $SERVER_OBJ->last_key_change();
        ok( $last_key_change, 'server received key change request' );

        is(
            $last_key_change->{'inner_payload'}{'account'},
            $old_key_id,
            'inner payload has correct account URL',
        );

        ok(
            exists $last_key_change->{'inner_payload'}{'oldKey'},
            'inner payload has oldKey field',
        );

        is(
            $last_key_change->{'inner_header'}{'url'},
            "https://" . MyCA->HOST() . "/my-key-change",
            'inner JWS has correct url header',
        );

        ok(
            exists $last_key_change->{'inner_header'}{'jwk'},
            'inner JWS has jwk header (new key)',
        );

        ok(
            !exists $last_key_change->{'inner_header'}{'nonce'},
            'inner JWS does not have nonce',
        );
    };
}

subtest 'change_key without key_id fails' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
        enable_key_change => 1,
    );

    my $acme = MyCA->new( key => $_RSA_KEY );

    throws_ok(
        sub { $acme->change_key($_NEW_RSA_KEY) },
        qr/key.?id/i,
        'change_key() requires key_id',
    );
};

done_testing();
