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

use Crypt::Format ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;

#----------------------------------------------------------------------

{
    package MyCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

my $_RSA_KEY  = <<END;
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

my $_P256_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKDv8TBijBVbTYB7lfUnwLn4qjqWD0GD7XOXzdp0wb61oAoGCCqGSM49
AwEHoUQDQgAEBJIULcFadtIBc0TuNzT80UFcfkQ0U7+EPqEJNXamG1H4/z8xVgE7
3hoBfX4xbN2Hx2p26eNIptt+1jj2H/M44g==
-----END EC PRIVATE KEY-----
END

my $_P384_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MIGkAgEBBDBqmQFgqovKRpzWs0JST9p/vtRQCHQi3r+6N2zoOorRv/JQoGMHZB+i
c4d7oLnMpx+gBwYFK4EEACKhZANiAATXy7Zwmz5s98iSrQ+Y6lZ56g8/1INa4GY2
LeDDedG+NvKKcj0P3uJV994RSyitrijBQvN2ccSuL67IHUQ3I4O7S7eKRNsU8R7K
3ljffUl1vtb6GnjPgSZgt2zugJCwlH8=
-----END EC PRIVATE KEY-----
END

my @alg_key = (
    [ rsa => $_RSA_KEY ],
    [ p256 => $_P256_KEY ],
    [ p384 => $_P384_KEY ],
);

for my $t (@alg_key) {
    my ($alg, $key_pem) = @$t;

    my $key_der = Crypt::Format::pem2der($key_pem);

    my @formats = (
        [ pem => $key_pem ],
        [ der => $key_der ],
    );

    for my $tt (@formats) {
        my ($format, $key_str) = @$tt;

        diag "$alg, $format";

        lives_ok(
            sub {
                my $SERVER_OBJ = Test::ACME2_Server->new(
                    ca_class => 'MyCA',
                );

                #----------------------------------------------------------------------
                # new()

                my $acme = MyCA->new( key => $key_str );
                isa_ok( $acme, 'MyCA', 'new() response' );

                #----------------------------------------------------------------------
                # get_terms_of_service()

                my $tos = $acme->get_terms_of_service();

                is( $tos, $SERVER_OBJ->TOS_URL(), 'get_terms_of_service' );

                #----------------------------------------------------------------------

                my $created = $acme->create_new_account(
                    termsOfServiceAgreed => 1,
                );

                is( $created, 1, 'create_new_account() on new account creation' );

                my $key_id = $acme->key_id();
                ok( $key_id, 'key_id() gets updated' );

                $created = $acme->create_new_account();
                is( $created, 0, 'create_new_account() if account already exists' );

                is( $acme->key_id(), $key_id, 'key_id() stays the same' );
            },
            "no errors: $alg, $format",
        );
    }
}

done_testing();
