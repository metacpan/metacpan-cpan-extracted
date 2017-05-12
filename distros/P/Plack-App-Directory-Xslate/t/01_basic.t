use strict;
use warnings;

use Test::More tests => 1;
use Plack::Test;
use Plack::App::Directory::Xslate;
use HTTP::Request;

my $app = Plack::App::Directory::Xslate->new({
    root => 't/htdocs/',
    xslate_opt  => +{
        cache => 0,
    },
    xslate_param => +{
        hoge => 'fuga',
    },
    xslate_path => qr{\.tx$},
})->to_app;

subtest 'Plack::Test' => sub {
    plan tests => 2;
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => 'http://localhost/test.txt');
            my $res = $cb->($req);
            is $res->content, 'Test <: $hoge :>', 'nomarl file';

            $req = HTTP::Request->new(GET => 'http://localhost/test.tx');
            $res = $cb->($req);
            is $res->content, 'Test fuga', 'template file';
        };
};
