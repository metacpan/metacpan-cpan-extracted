use strict;
use warnings;
use Cache::Memory::Simple;
use HTTP::CookieJar;
use HTTP::Request::Common;
use Mojolicious::Lite;
use Mojo::Server::PSGI;
use MojoX::Session::Simple;
use Plack::Builder;
use Plack::Loader;
use Plack::LWPish;
use Test::Mojo;
use Test::More;
use Test::Pretty;
use Test::TCP;

app->sessions(
    MojoX::Session::Simple->new({
        default_expiration => 2,
    }),
);

get '/' => sub {
    my $c = shift;
    $c->session->{now} ||= time;
    $c->render(text => $c->session->{now});
};

my $app = builder {
    enable 'Session::Simple',
        store => Cache::Memory::Simple->new,
        cookie_name => 'myapp_session';

    Mojo::Server::PSGI->new({ app => Test::Mojo->new->app })->to_psgi_app;
};

my $server = sub {
    my $port = shift;
    Plack::Loader->load('Standalone', port => $port)->run($app);
};

test_tcp(
    server => $server,
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new,
        );

        subtest 'Test session expires' => sub {
            my $res1 = $ua->request(GET "http://localhost:$port/");
            my $res2 = $ua->request(GET "http://localhost:$port/");
            sleep 2;
            my $res3 = $ua->request(GET "http://localhost:$port/");

            is $res2->content, $res1->content;
            isnt $res3->content, $res2->content;
        };
    },
);

done_testing;
