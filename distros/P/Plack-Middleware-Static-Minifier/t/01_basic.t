use strict;
use warnings;
use Test::More 0.88;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;
use Cwd;

my $base = cwd;

my $handler = builder {
    enable 'Plack::Middleware::Static::Minifier',
        path => sub { s!^/share/!!}, root => 'share';
    mount '/' => builder {
        sub {
            [200, [], ['ok']]
        };
    };
};
my %test = (
    client => sub {
        my $cb  = shift;
        {
            note('not static');
            my $res = $cb->(GET 'http://localhost/');
            is $res->content, 'ok';
        }

        {
            note('jpg no minify');
            my $res = $cb->(GET 'http://localhost/share/face.jpg');
            is $res->content_type, 'image/jpeg';
        }

        {
            note('text no minify');
            my $res = $cb->(GET 'http://localhost/share/foo.txt');
            is $res->content_type, 'text/plain';
            is $res->content, "text\ntest";
        }

        {
            note('minify CSS');
            my $res = $cb->(GET 'http://localhost/share/try.css');
            is $res->content_type, 'text/css';
            is $res->content, 'html{margin:0;padding:0}body{margin:0;padding:0}';
        }

        {
            note('minify JavaScript');
            my $res = $cb->(GET 'http://localhost/share/try.js');
            is $res->content_type, 'application/javascript';
            is $res->content, "(function(){var akb=48;var name='Mariko';})();";
        }

        {
            note('not 200');
            my $res = $cb->(GET 'http://localhost/share/not_found.css');
            is $res->code, 404;
        }
    },
    app => $handler,
);

test_psgi %test;

my $handler2 = builder {
    enable 'Plack::Middleware::Static::Minifier',
        path => sub { s!^/share/!!}, root => 'share', pass_through => 1;
    sub {
        [200, [], ['ok']]
    };
};
my %test2 = (
    client => sub {
        my $cb  = shift;
        note('pass through');
        {
            my $res = $cb->(GET 'http://localhost/share/try.css');
            is $res->code, 200;
            is $res->content, 'html{margin:0;padding:0}body{margin:0;padding:0}';

            $res = $cb->(GET 'http://localhost/share/not_found.css');
            is $res->code, 200;
            is $res->content, 'ok';
            is $res->content_type, '';
        }
    },
    app => $handler2,
);

test_psgi %test2;

my $handler3 = builder {
    enable 'Plack::Middleware::Static::Minifier',
        path => sub { s!^/share/!! }, root => 'share', cache => MyCacheMock->new;
    sub {
        [200, [], ['ok']]
    };
};
my %test3 = (
    client => sub {
        my $cb = shift;
        note('cache');
        {
            my $res = $cb->(GET 'http://localhost/share/try.css');
            is $res->code, 200;
            is $res->content, 'html{margin:0;padding:0}body{margin:0;padding:0}';
            is $res->content_type, 'text/css';

            $res = $cb->(GET 'http://localhost/share/try.css');
            is $res->code, 200;
            is $res->content, 'html{margin:10px;padding:10px}'; # cached content
            is $res->content_type, 'text/css';
        }
    },
    app => $handler3,
);

test_psgi %test3;

done_testing;

package MyCacheMock;
sub new { bless +{}, shift }
sub set { $_[0]->{ $_[1] } = 'html{margin:10px;padding:10px}' }
sub get { $_[0]->{ $_[1] } }
