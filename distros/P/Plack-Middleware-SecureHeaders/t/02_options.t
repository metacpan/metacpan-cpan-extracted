use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use HTTP::SecureHeaders;

subtest 'Content-Security-Policy option' => sub {
    my $value = "default-src 'self'";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            content_security_policy => $value
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('Content-Security-Policy'), $value;
    };
};

subtest 'Strict-Transport-Security option' => sub {
    my $value = "max-age=31536000; includeSubDomains";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            strict_transport_security => $value,
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('Strict-Transport-Security'), $value;
    };
};

subtest 'X-Frame-Options option' => sub {
    my $value = "DENY";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            x_frame_options => $value,
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('X-Frame-Options'), $value;
    };
};

subtest 'X-Permitted-Cross-Domain-Policies option' => sub {
    my $value = "master-only";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            x_permitted_cross_domain_policies => $value,
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('X-Permitted-Cross-Domain-Policies'), $value;
    };
};

subtest 'X-XSS-Protection option' => sub {
    my $value = "1";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            x_xss_protection => $value,
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('X-XSS-Protection'), $value;
    };
};

subtest 'Referrer-Policy option' => sub {
    my $value = "no-referrer";

    my $app = builder {
        enable 'SecureHeaders', secure_headers => HTTP::SecureHeaders->new(
            referrer_policy => $value,
        );
        sub { [ 200, ['Content-Type' => 'text/plain'], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->header('Referrer-Policy'), $value;
    };
};

done_testing;
