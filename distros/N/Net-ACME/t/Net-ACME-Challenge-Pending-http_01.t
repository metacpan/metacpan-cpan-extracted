package t::Net::ACME::Challenge::Pending::http_01;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use File::Slurp ();
use File::Temp ();

use Net::ACME::Challenge::Pending::http_01 ();

use Net::ACME::Constants ();
use Net::ACME::Utils     ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub _KEY {
    return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAw65MxcsV0bL2T0eTFe220RynlXj1+CqN2MP5FbWEkFApqIXm
XBiq/1fp1Emq/M26AalyYtYAA/lDpGYmsUzau39AyOwOvA4Qr87NmWluys/k5IHm
HqxmuDtW/Hmh+MW0HV29a+5eFjTJX5654K4D9cxqkc29v+gnzzE+NuMEX7Cid38q
YgcY7dkfkOc+vunFCdGMXv+GcSeByGCeXsHApszti0zUNu8xWqN5bAKo/TJpgIVU
KG96uVvZ0ydPRDWMK25/LH5cSQMmmCruBV8d0LLFxLKqczH5D7jmftvw/HrnsMX0
iBcJYVnFJXca4A84gGqozECXVuH3OgCjnGhr3wIDAQABAoIBADhhiUdYS5IfMW8I
XW3tD0bTLcoYjy6Q/Evfs2443dhC8K3Y3tXcWbC24O3EyBqNIDIIY6fspxZ+BKpi
sHVXgpKRiNYbhedTWiV9vamdQkn3eqkIcIiX/gTJPDgEx9GJDWuEreZiSQO28+q0
LjR5jzSMUIxwLmMT/hxpwNZJtOHo3sPPFS6MrrZq1RtgtoqW3T9ESfh2EAst8glm
RoO9vskkPNWHHs0aOsuRHwYochhJM5Ihfh2kt7NMZzFnAzyOsfbj5RFdkss/Z4IJ
UraDC9zrx/WY9fVwc3gZkzRi/vCBUZUs8YpgWBdTOzbdRJM458eX/HRjA2jQ6P+i
T/lvq5ECgYEA7VaU5MBCXHvzr6rvEQGbHqWHjltn4wUUUUKd21yjwndXY04lJlf5
jHsZ2XRVUkNu4dxeqmIUqLjJL9mVyLle/q9etAbIm9KMyvatrufuBgK1fFCFaDnc
MvPLBvwR8CHmohkPwA3UpqC4Kqo17dEQypMWZjTp5uyEAaY3vmJhwqcCgYEA0xEw
3UKgSnfr+mU/H9pT3ydiChjLmJ0jdIi9N9EM3PHa5MpXB6gzpHEu8k9YTgaMLYko
aKF7RYJTwIXo0zbFYdmG1vBCSILntnU2vTZj5ZNmcB0dHjzhqHBEijkoSfzqfoap
ylx9RZGAjqv/5+WVcVK586gB8i8CaQXSzCY5TAkCgYAatjPryvetEQZMLyDY+SVM
PbUUAJWgp2GyA51govyLVoMvWgw0VJJxjSlLoBw6Nfy0zuiYpJFOq/14tTR2cuaO
I461FE5fu0K9VSYXGWNgqc1jQGzDXj+6PFYNYzFhpW8fr1JmeygD2PLhWmbXbUBG
jGdo+WuZ4eS5isubUddO4QKBgAsQ36r6D0VYPDsIi+Kzo6oTeoRlAGej9XPqp2EB
yNbcp0lPgniYTPzWIkv59PtCRJ8ujbvOm5PtXU6+tpI8UOTsbrFeL1t14YgjZRdO
frZOoBRIsnofXwVhvXYxwPcAF5tCnCxL5RV8p2zTf7s8wjUKzU0FBfUYmdu/vmmN
p3thAoGBALzFFXhtZ1P+P4DPo8NUagpBl4mEzVW6EMCWpJ8mAjHfXwHCfooMUQ7r
1KT23I/e0o0kjc67bBhRdYaoeLNFnazN9CqPuqsKhfCWU9w4Uu/oraD3QiSf9ECT
fzO63bNpgeF1Djw2RmtnpchhUZ63A6IrgqfwQrUVeKtxPknYcMvV
-----END RSA PRIVATE KEY-----
END
}

sub do_tests : Tests(4) {
    my ($self) = @_;

    my $challenge = Net::ACME::Challenge::Pending::http_01->new(
        token => 'the_token',
        uri   => 'http://the/challenge/uri',
    );

    is( $challenge->token(), 'the_token', 'token()' );
    is( $challenge->uri(), 'http://the/challenge/uri', 'uri()' );

    my $key_obj = Net::ACME::Crypt::parse_key(_KEY());
    my $jwk     = $key_obj->get_struct_for_public_jwk();

    my $scratch_dir = File::Temp::tempdir( CLEANUP => 1 );

    my $handler = $challenge->create_handler(
        $scratch_dir,
        $jwk,
    );

    my $relative_path = "$Net::ACME::Constants::HTTP_01_CHALLENGE_DCV_DIR_IN_DOCROOT/the_token";

    is(
        File::Slurp::read_file("$scratch_dir/$relative_path"),
        'the_token.NHDpucT75mJ9q2JOrBsMxI01r_xjdj9gx5OGEGzZvv8',
        'DCV file contents',
    );

    undef $handler;

    ok(
        !( -e "$scratch_dir/$relative_path" ),
        'after handler DESTROYed, DCV file is gone',
    );

    return;
}

1;
