use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Nephia::Core;

my $v = Nephia::Core->new(
    plugins => [
        'View::MicroTemplate' => { 
            include_path => [File::Spec->catdir(qw/t tmpl/)],
        }, 
        'JSON',
        'ResponseHandler',
    ],
    app => sub {
        my $req = req();
        $req->path_info eq '/json'   ? +{foo => 'bar'} :
        $req->path_info eq '/html'   ? +{name => 'html', template => 'foo.html'} :
        $req->path_info eq '/js'     ? +{name => 'js', template => 'bar.js', content_type => 'text/javascript'} :
        $req->path_info eq '/array'  ? [200, ['Content-Type' => 'text/plain; charset=UTF-8'], 'foobar'] :
        $req->path_info eq '/scalar' ? 'scalar!' :
                                       [404, ['Content-Type' => 'text/html; charset=UTF-8'], 'not found']
        ;
    },
);

subtest json => sub {
    test_psgi $v->run, sub {
        my $cb = shift;
        my $res = $cb->(GET '/json');
        is $res->content, '{"foo":"bar"}', 'output JSON';
        is $res->header('Content-Type'), 'application/json; charset=UTF-8';
    };
};

subtest html => sub {
    test_psgi $v->run, sub {
        my $cb = shift;
        my $res = $cb->(GET '/html');
        is $res->content, 'Hello, html!'."\n", 'output HTML';
        is $res->header('Content-Type'), 'text/html; charset=UTF-8';
    };
};

subtest js => sub {
    test_psgi $v->run, sub {
        my $cb = shift;
        my $res = $cb->(GET '/js');
        is $res->content, 'alert("Hello, js!");'."\n", 'output JS';
        is $res->header('Content-Type'), 'text/javascript';
    };
};

subtest array => sub {
    test_psgi $v->run, sub {
        my $cb = shift;
        my $res = $cb->(GET '/array');
        is $res->content, 'foobar', 'output ARRAY';
        is $res->header('Content-Type'), 'text/plain; charset=UTF-8';
    };
};

subtest scalar => sub {
    test_psgi $v->run, sub {
        my $cb = shift;
        my $res = $cb->(GET '/scalar');
        is $res->content, 'scalar!', 'output SCALAR';
        is $res->header('Content-Type'), 'text/html; charset=UTF-8';
    };
};

done_testing;
