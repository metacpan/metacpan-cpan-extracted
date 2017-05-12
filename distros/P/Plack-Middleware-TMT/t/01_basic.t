use strict;
use Plack::Builder;
use HTTP::Request::Common;
use LWP::UserAgent;

use Test::More 0.88;
use Plack::Test;

{
    note 'simple';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'OK';
    };
    test_psgi $app, $cli;
}

{
    note 'tmpl_extension';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl',
            tmpl_extension => '.mt';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'OK .mt';
    };
    test_psgi $app, $cli;
}

{
    note 'simple path';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/foo');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'foo OK';
    };
    test_psgi $app, $cli;
}

{
    note 'deep path default';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/bar/');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'index OK';
    };
    test_psgi $app, $cli;
}

{
    note 'deep path';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/bar/baz');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'bar/baz OK';
    };
    test_psgi $app, $cli;
}

{
    note 'param';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/hoge?hoge=123');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, '123 OK';
    };
    test_psgi $app, $cli;
}

{
    note 'macro';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl',
            macro => +{
                hello => sub { 'hello macro!' },
            };
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/macro');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, 'hello macro!';
    };
    test_psgi $app, $cli;
}

{
    note 'macro dumper';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/macro_dumper');
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content, <<"_EXPECT_";
{
  &#39;bar&#39; =&gt; 456,
  &#39;foo&#39; =&gt; 123
}
_EXPECT_
    };
    test_psgi $app, $cli;
}

{
    note 'template not exists';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl';
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/noexists');
            is $res->code, 404;
            is $res->content_type, 'text/plain';
            is $res->content, 'Not Found';
    };
    test_psgi $app, $cli;
}

my $base_app = sub { [ 201, ['Content-Type' => 'text/plain'], ['201 OK'] ] };
{
    note 'pass through';
    my $app = builder {
        enable 'TMT',
            include_path => 'tmpl',
            pass_through => 1;
        $base_app,
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/noexists');
            is $res->code, 201;
            is $res->content_type, 'text/plain';
            is $res->content, '201 OK';
    };
    test_psgi $app, $cli;
}

done_testing;
