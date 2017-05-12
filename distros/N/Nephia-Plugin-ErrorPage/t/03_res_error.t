use strict;
use warnings;
use Test::More;
use Nephia::Core;
use Plack::Test;
use HTTP::Request::Common;

subtest res_error => sub {
    my $v = Nephia::Core->new(
        appname => 'MyTestApp',
        plugins => [ 'ErrorPage' ],
        app     => sub {
            res_error(403);
        },
    );
    
    my $app = $v->run;
    
    test_psgi($app => sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->code, 403;
        like $res->content, qr/403/; 
        like $res->content, qr/Forbidden/;
    });
};

done_testing;

