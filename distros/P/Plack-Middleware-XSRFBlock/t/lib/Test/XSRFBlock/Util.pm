package Test::XSRFBlock::Util;
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [
        qw(
            forbidden_ok
            set_cookie_ok
            cookie_in_jar_ok
        ),
    ],
};

use HTTP::Status ':constants';
use Test::More;

sub forbidden_ok {
    my $res = shift;
    is (
        $res->code,
        HTTP_FORBIDDEN,
        sprintf(
            '"POST %s" returns HTTP_FORBIDDEN(%d)',
            $res->request->uri,
            HTTP_FORBIDDEN
        )
    );
    return $res;
}

sub set_cookie_ok {
    my $res = shift;
    my $h_cookie = $res->header('Set-Cookie') || '';
    $h_cookie =~ /PSGI-XSRF-Token=([^; ]+)/;
    my $token_from_cookie = $1 || '';
    ok(
        $token_from_cookie,
        'cookie being set with a non-blank value'
    );
}

sub cookie_in_jar_ok {
    my $res = shift;
    my $jar = shift;
    my $msg = shift ||
        'cookie has a defined value when retrieved';

    $jar->extract_cookies($res);
    like(
        $jar->as_string,
        qr{PSGI-XSRF-Token},
        'PSGI-XSRF-Token found in cookie jar',
    );
    my $token = _cookie_value($jar, 'PSGI-XSRF-Token');
    ok(
        defined $token,
        $msg
    );

    return $token;
}

sub _cookie_value {
    my $jar = shift;
    my $cookie_name = shift || return;

    my $token;
    $jar->scan(
        sub{$token = $_[2] if $_[1] eq $cookie_name;}
    );
    return $token;
}

1;
