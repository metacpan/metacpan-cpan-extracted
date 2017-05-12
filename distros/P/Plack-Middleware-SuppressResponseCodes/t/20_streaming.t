use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;

my $app = builder {
    enable 'SuppressResponseCodes';
    sub {
        return sub {
            my $responder = shift;
            $responder->(['400',[],['error']]);
        };
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => "/?suppress_response_codes"));
    is $res->code, 200, 'suppressed';
    is $res->content, 'error';
};
 
done_testing;
