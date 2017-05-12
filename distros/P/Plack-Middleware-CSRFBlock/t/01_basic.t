use Test::More;

use strict;
use warnings;

use Plack::Test;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Session::State::Cookie;

my $form = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_outside = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://example.com/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
        <form action="http://example.com:80/post" method="post">
            <input type="text" name="text" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_localhost = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://localhost/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_localhost_port = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://localhost:80/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $base_app = sub {
    my $req = Plack::Request->new(shift);
    my $name = $req->param('name') or die 'name not found';
    return  [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello " . $name ] ]
};


my $mapped = builder {
    mount "/post" => $base_app;
    mount "/form/html" => sub { [ 200, [ 'Content-Type' => 'text/html' ], [ $form ] ] };
    mount "/form/xhtml" => sub { [ 200, [ 'Content-Type' => 'application/xhtml+xml' ], [ $form ] ] };
    mount "/form/text" => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ $form ] ] };
    mount "/form/html-charset" => sub { [ 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], [ $form ] ] };
    mount "/form/xhtml-charset" => sub { [ 200, [ 'Content-Type' => 'application/xhtml+xml; charset=UTF-8' ], [ $form ] ] };
    mount "/form/text-charset" => sub { [ 200, [ 'Content-Type' => 'text/plain; charset=UTF-8' ], [ $form ] ] };

    mount "/form/html-outside" => sub { [ 200, [ 'Content-Type' => 'text/html' ], [ $form_outside ] ] };
    mount "/form/html-localhost" => sub { [ 200, [ 'Content-Type' => 'text/html' ], [ $form_localhost ] ] };
    mount "/form/html-localhost-port" => sub { [ 200, [ 'Content-Type' => 'text/html' ], [ $form_localhost_port ] ] };
};

# normal input
my $app1 = builder {
    enable 'Session', state => Plack::Session::State::Cookie->new(session_key => 'sid');
    enable 'CSRFBlock';
    $mapped;
};

# psgix.input.buffered
my $app2 = builder {
    enable 'Session', state => Plack::Session::State::Cookie->new(session_key => 'sid');
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $content = $req->content; # <<< force psgix.input.buffered true.
            $app->($env);
        };
    };
    enable 'CSRFBlock';
    $mapped;
};

for my $app ($app1, $app2) {

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(POST "http://localhost/post", [name => 'Plack']);
    is $res->code, 403;

    my $h_cookie = $res->header('Set-Cookie');
    $h_cookie =~ /sid=([^; ]+)/;
    my $sid = $1;

    ok($sid);

    $res = $cb->(POST "http://localhost/post", [name => 'Plack'], Cookie => "sid=$sid");
    is $res->code, 403, 'Forbidden for CSRF';
    $res = $cb->(POST "http://localhost/post", [SEC => '1234567890123456', name => 'Plack'], Cookie => "sid=$sid");
    is $res->code, 403, 'Forbidden for faked token';

    $res = $cb->(GET "http://localhost/form/html", Cookie => "sid=$sid");
    is $res->code, 200, 'form /form/html';
    ok $res->content =~ /<input type="hidden" name="SEC" value="([0-9a-f]{16})" \/>/, 'form_has_token /form/html';
    my $token = $1;

    # Make sure we *dont* have the meta header here
    ok $res->content !~ /<meta name="csrftoken" content="([0-9a-f]{8})"\/>/;

    $res = $cb->(GET "http://localhost/form/html-charset", Cookie => "sid=$sid");
    is $res->code, 200, 'form /form/html-charset';
    ok $res->content =~ /<input type="hidden" name="SEC" value="([0-9a-f]{16})" \/>/, 'form_has_token /form/html-charset';
    is $1, $token, 'same token for same sid';

    $res = $cb->(GET "http://localhost/form/html-outside", Cookie => "sid=$sid");
    is $res->code, 200, 'form /form/html-outside';
    ok $res->content !~ /<input type="hidden" name="SEC" value="([0-9a-f]{16})" \/>/, 'form_has_not_token /form/html-outside';

    $res = $cb->(GET "http://localhost/form/html-localhost", Cookie => "sid=$sid");
    is $res->code, 200, 'form /form/html-localhost';
    ok $res->content =~ /<input type="hidden" name="SEC" value="([0-9a-f]{16})" \/>/, 'form_has_token /form/html-localhost';
    is $1, $token, 'same token for same sid again';

    $res = $cb->(GET "http://localhost/form/html-localhost-port", Cookie => "sid=$sid");
    is $res->code, 200, 'form /form/html-localhost-port';
    ok $res->content =~ /<input type="hidden" name="SEC" value="([0-9a-f]{16})" \/>/, 'form_has_token /form/html-localhost-port';
    is $1, $token, 'same token for same sid again2';

    # application/x-www-form-urlencoded
    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'application/x-www-form-urlencoded'
    );
    is $res->code, 200, 'correct token returns 200';
    is $res->content, 'Hello Plack', 'name param';

    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, x => 'x' x 20000, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'application/x-www-form-urlencoded'
    );
    is $res->code, 200, 'correnct token returns 200 / long body';
    is $res->content, 'Hello Plack', 'name param / long body';

    # multipart/form-data
    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'multipart/form-data'
    );
    is $res->code, 200, 'correct token returns 200 / multipart/form-data';
    is $res->content, 'Hello Plack', 'name param / multipart/form-data';

    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, x => 'x' x 20000, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'multipart/form-data'
    );
    is $res->code, 200, 'correct token returns 200 / long body / multipart/form-data';
    is $res->content, 'Hello Plack', 'name param / long body / multipart/form-data';

    # application/x-www-form-urlencoded; charset=UTF-8
    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'application/x-www-form-urlencoded; chartset=UTF-8'
    );
    is $res->code, 200, 'correct token returns 200 / charset';
    is $res->content, 'Hello Plack', 'name param / charset';

    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, x => 'x' x 20000, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'application/x-www-form-urlencoded; chartset=UTF-8'
    );
    is $res->code, 200, 'correct token returns 200 / long body / charset';
    is $res->content, 'Hello Plack', 'name param / long body /charset';

    # multipart/form-data; charset=UTF-8
    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'multipart/form-data; chartset=UTF-8'
    );
    is $res->code, 200, 'correct token returns 200 / long body / multipart/form-data / charset';
    is $res->content, 'Hello Plack', 'name param / long body / multipart/form-data / charset';

    $res = $cb->(POST "http://localhost/post",
        [SEC => $token, x => 'x' x 20000, name => 'Plack'],
        Cookie => "sid=$sid",
        'Content-Type' => 'multipart/form-data; chartset=UTF-8'
    );
    is $res->code, 200;
    is $res->content, 'Hello Plack';

    # supported content-type
    $res = $cb->(GET "http://localhost/form/xhtml", Cookie => "sid=$sid");
    like $res->content, qr/<input type="hidden" name="SEC" value="$token" \/>/, 'xhtml form has token';
    $res = $cb->(GET "http://localhost/form/text", Cookie => "sid=$sid");
    unlike $res->content, qr/<input type="hidden" name="SEC" value="$token" \/>/, 'text form has not token';

    $res = $cb->(GET "http://localhost/form/xhtml-charset", Cookie => "sid=$sid");
    like $res->content, qr/<input type="hidden" name="SEC" value="$token" \/>/, 'xhtml-charset form has token';
    $res = $cb->(GET "http://localhost/form/text-charset", Cookie => "sid=$sid");
    unlike $res->content, qr/<input type="hidden" name="SEC" value="$token" \/>/, 'text-charset form has token';
};

}; # for my $app ($app1,$app2)


# customized parameter
my $app3 = builder {
    enable 'Session', , state => Plack::Session::State::Cookie->new(session_key => 'sid');
    enable 'CSRFBlock',
        token_length => 8,
        parameter_name => 'TKN',
        onetime => 1,
        blocked => sub {
            [ 404,
                ['Content-Type' => 'text/plain'],
                [ 'csrf' ]
            ]
        }
    ;
    $mapped;
};

test_psgi app => $app3, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/form/xhtml");
    is $res->code, 200, 'w/param form';

    my $h_cookie = $res->header('Set-Cookie');
    $h_cookie =~ /sid=([^; ]+)/;
    my $sid = $1;

    ok $res->content =~ /<input type="hidden" name="TKN" value="([0-9a-f]{8})" \/>/;
    my $token = $1;
    $res = $cb->(POST "http://localhost/post", [TKN => $token, name => 'Plack'], Cookie => "sid=$sid");
    is $res->code, 200, 'w/param:onetime token use firsttime';
    $res = $cb->(POST "http://localhost/post", [TKN => $token, name => 'Plack'], Cookie => "sid=$sid");
    is $res->code, 404, 'w/param:onetime second token use';
    is $res->content, 'csrf', 'w/param:blocked custom blocked app';

    for(1..2) {
        $res = $cb->(GET "http://localhost/form/xhtml", Cookie => "sid=$sid");
        is $res->code, 200, 'w/param form again';
        ok $res->content =~ /<input type="hidden" name="TKN" value="([0-9a-f]{8})" \/>/;
        isnt $1, $token, 'w/param:onetime token changed';
        $token = $1;

        $res = $cb->(POST "http://localhost/post", [TKN => $token, name => 'Plack'], Cookie => "sid=$sid");
        is $res->code, 200, 'w/param:onetime new token used';
    }

    $res = $cb->(POST "http://localhost/post", [TKN => $token, name => 'Plack'], Cookie => "sid=$sid");
    is $res->code, 404, 'w/param:onetime second token use again';
    is $res->content, 'csrf', 'w/param:blocked custom blocked app again';
};

# Test Meta Tag + Header
my $app4 = builder {
    enable 'Session',
        state => Plack::Session::State::Cookie->new(session_key => 'sid');
    enable 'CSRFBlock', token_length => 8, meta_tag => 'csrftoken';
    $mapped;
};

test_psgi app => $app4, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/form/html");
    is $res->code, 200;

    my $h_cookie = $res->header('Set-Cookie');
    $h_cookie =~ /sid=([^; ]+)/;
    my $sid = $1;

    ok $res->content =~ /<input type="hidden" name="SEC" value="([0-9a-f]{8})" \/>/;
    my $token = $1;
    ok $res->content =~ /<meta name="csrftoken" content="([0-9a-f]{8})"\/>/;
    my $meta_token = $1;

    is $token => $meta_token, 'Got correct token in meta tag';

    $res = $cb->(
        POST "http://localhost/post",
        [name => 'Plack'],
        Cookie => "sid=$sid", 'X-CSRF-Token' => $meta_token
    );
    is $res->code, 200, 'w/Token in Header Only';
};

done_testing;
