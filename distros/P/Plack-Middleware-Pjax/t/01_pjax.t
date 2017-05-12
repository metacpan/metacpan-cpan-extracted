use Plack::Test;
use Test::More tests => 10;
use Plack::Builder;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Middleware::Pjax;

# wrapper for builder {} for each test
sub psgi_app {
    my $body = shift;
    builder {
        enable 'Plack::Middleware::Pjax';
        sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ]; };
    }
};
# gracious thanks to rack-pjax, tests converted from there
test_psgi
psgi_app('<html><title>Hello</title><body><div data-pjax-container>World!</div></body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true');
    is $res->content, '<title>Hello</title>World!', 'should return the title-tag in the body';
};

test_psgi
psgi_app('<html><body><div data-pjax-container>World!</div></body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true');
    is $res->content, 'World!', 'should return the inner-html of the pjax-container in the body';
};


# a pjaxified app, upon receiving a pjax-request
test_psgi
psgi_app('<html><body><div data-pjax-container><article>World!<img src="test.jpg" /></article></div></body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true');
    is $res->content, '<article>World!<img src="test.jpg" /></article>', 'should handle self closing tags with HTML5 elements';

    is $res->header('Content-Length'), length $res->content, 'should return the correct Content Length';
};

test_psgi
psgi_app('<html><body>Has no pjax-container</body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true');
    is $res->content, '<html><body>Has no pjax-container</body></html>', 'should return the original body when there is no pjax-container';
};

test_psgi
psgi_app(<<BODY
<html>
<div data-pjax-container>
 <p>
first paragraph</p> <p>Second paragraph</p>
</div>
</html>
BODY
),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true');
    is $res->content, "\n <p>\nfirst paragraph</p> <p>Second paragraph</p>\n", 'should preserve whitespaces of the original body';
};

# a pjaxified app, upon receiving a non-pjax request
test_psgi
psgi_app('<html><title>Hello</title><body><div data-pjax-container>World!</div></body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is $res->content, '<html><title>Hello</title><body><div data-pjax-container>World!</div></body></html>', 'a pjaxified app, upon receiving a non-pjax request should return the original body';
    SKIP: {
        skip "PSGI by default doesn't set Content-Length, unlike Rack", 1;
        is $res->header('Content-Length'), length $res->content, 'should return the correct Content Length';
    };
};

test_psgi
psgi_app('<html><title>Hello</title><body><div data-foo-container>World!</div></body></html>'),
sub {
    my $cb = shift;
    my $res = $cb->(GET '/', 'X_PJAX' => 'true', 'X_PJAX_CONTAINER' => 'data-foo-container');
    is $res->content, '<title>Hello</title>World!', 'a pjaxified app, upon receiving a non-pjax request should return the correct body';
    is $res->header('Content-Length'), length $res->content, 'should return the correct Content Length';
};
