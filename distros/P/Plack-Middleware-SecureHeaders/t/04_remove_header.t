use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

subtest 'If undef, it is removed from the HTTP header' => sub {
    my $app = builder {
        enable 'SecureHeaders';
        sub { [ 200, [
            'Content-Type' => 'text/plain',
            'Content-Security-Policy'           => undef,
            'Strict-Transport-Security'         => undef,
            'X-Content-Type-Options'            => undef,
            'X-Download-Options'                => undef,
            'X-Frame-Options'                   => undef,
            'X-Permitted-Cross-Domain-Policies' => undef,
            'X-XSS-Protection'                  => undef,
            'Referrer-Policy'                   => undef,
        ], ['HELLO WORLD'] ] };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->code, 200, 'response status 200';

        is $res->header('Content-Security-Policy')           => undef;
        is $res->header('Strict-Transport-Security')         => undef;
        is $res->header('X-Content-Type-Options')            => undef;
        is $res->header('X-Download-Options')                => undef;
        is $res->header('X-Frame-Options')                   => undef;
        is $res->header('X-Permitted-Cross-Domain-Policies') => undef;
        is $res->header('X-XSS-Protection')                  => undef;
        is $res->header('Referrer-Policy')                   => undef;

        is_deeply [$res->headers->header_field_names], ['Content-Type'], 'Content-Type only';
    };
};

done_testing;
