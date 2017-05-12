use strict;
use warnings;
use Test::More;
use Nephia::Core;
use Plack::Test;
use HTTP::Request::Common;

subtest res_404 => sub {
    my $v = Nephia::Core->new(
        appname => 'MyTestApp',
        plugins => [ 'ErrorPage' ],
        app     => sub {
            res_404();
        },
    );
    
    my $app = $v->run;
    
    test_psgi($app => sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->code, '404';
        like $res->content, qr/404/; 
        like $res->content, qr/Not Found/;
    });
};

done_testing;

