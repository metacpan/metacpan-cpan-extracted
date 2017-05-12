use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Test::More;

my $body = ['FOO'];
my $app;

$app = builder {
  enable "Plack::Middleware::LowerUrl";
  sub {
    my $env = shift;
    is $env->{REQUEST_URI}, '/foo?TEST=1';
    is $env->{PATH_INFO}, '/foo';
    [200, ['Content-Type', 'text/html', 'Content-Length', length(join '', $body)], $body];
  };
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/foo?TEST=1');
    is $res->code, 200;
    is $res->content, 'FOO';
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/fOo?TEST=1');
    is $res->code, 200;
    is $res->content, 'FOO';
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/FOo?TEST=1');
    is $res->code, 200;
    is $res->content, 'FOO';
};

done_testing;
