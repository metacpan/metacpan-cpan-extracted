use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;

my $app = builder {
    enable 'SuppressResponseCodes';
    sub { [ substr($_[0]->{PATH_INFO},1), [], [] ] };
};

test_psgi $app, sub {
    my $cb = shift;

    foreach my $code (400,500) {
        foreach my $url (
            "/$code", 
            "/$code?suppress_response_codes=0",
            "/$code?suppress_response_codes=false") {
            my $res = $cb->(HTTP::Request->new(GET => $url));
            is $res->code, $code, 'not suppressed';
        }
        foreach my $url (
            "/$code?suppress_response_codes", 
            "/$code?foo=bar&suppress_response_codes=", 
            "/$code?suppress_response_codes=1") {
            my $res = $cb->(HTTP::Request->new(GET => $url));
            is $res->code, 200, 'suppressed';
        }
    }

    foreach my $code (100,200,300) {
        my $res = $cb->(HTTP::Request->new(GET => "/$code?suppress_response_code"));
        is $res->code, $code, 'no error';
    }
};

done_testing;
