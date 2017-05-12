use strict;
use warnings;
use Test::More;
use Nephia::Core;
use Plack::Test;
use HTTP::Request::Common;

my $v = Nephia::Core->new(
    appname => 'MyApp',
    app => sub {
        my $name = param('name') || 'tonkichi';
        [200,[],"Hello, $name"];
    },
);

my $app = $v->run;

subtest default => sub {
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->content, 'Hello, tonkichi';
        $res = $cb->(GET '/?name=ytnobody');
        is $res->content, 'Hello, ytnobody';
    };
};

done_testing;
