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
    MojoX::Session::Simple->new,
);

get '/' => sub {
    my $c = shift;
    $c->render(text => $c->session->{name} || '');
};

post '/login' => sub {
    my $c = shift;
    $c->session->{name} = 'Hoge';
    $c->render(text => 'OK');
};

post '/secure_login' => sub {
    my $c = shift;
    $c->session->{name} = 'Fuga';
    $c->session->{regenerate} = 1;
    $c->render(text => 'OK');
};

post '/reload' => sub {
    my $c = shift;
    $c->session->{regenerate} = 1;
    $c->render(text => 'OK');
};

post '/logout' => sub {
    my $c = shift;
    $c->session->{expires} = 1;
    $c->render(text => 'OK');
};

get '/flash' => sub {
    my $c = shift;
    $c->render(text => $c->flash('hoge') || '');
};

post '/flash' => sub {
    my $c = shift;
    $c->flash('hoge' => 'HogeFuga');
    $c->render(text => 'OK');
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

# Simple login and logout
test_tcp(
    server => $server,
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new,
        );

        subtest 'Test the first GET /' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            is $res->content, "";
            ok $res->header('set-cookie') =~ qr|myapp_session=([0-9a-f\-]+);|;
        };

        subtest 'Test POST /login' => sub {
            my $res = $ua->request(POST "http://localhost:$port/login", { });

            is $res->content, 'OK';
            is $res->header('set-cookie'), undef, 'no set-cookie header if session exists';
        };

        subtest 'Test GET / after login' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            is $res->content, "Hoge";
        };

        subtest 'Test POST /logout' => sub {
            my $res = $ua->request(POST "http://localhost:$port/logout");

            is $res->content, 'OK';
        };

        subtest 'Test GET / after logging out' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            is $res->content, "";
        };
    },
);

# Session 'sid' Regeneration
test_tcp(
    server => $server,
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new,
        );

        my $cookie;

        subtest 'Test POST /login to create session' => sub {
            my $res = $ua->request(POST "http://localhost:$port/login");

            ok $res->header('set-cookie') =~ /myapp_session=(.+?);/;

            $cookie = $1;
        };

        subtest 'Test POST /reload regenerates session' => sub {
            my $res = $ua->request(POST "http://localhost:$port/reload", { });

            is $res->content, 'OK';
            ok $res->header('set-cookie') =~ /myapp_session=(.+?);/;
            isnt $1, $cookie, 'sid was regenerated';
        };

        subtest 'Test GET / after reload' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            is $res->content, "Hoge";
        };
    },
);

# Secure login with sid regeneration
test_tcp(
    server => $server,
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new,
        );

        my $cookie;

        subtest 'Test GET / to start up initial session' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            ok $res->header('set-cookie') =~ /myapp_session=(.+?);/;

            $cookie = $1;
        };

        subtest 'Test POST /secure_login' => sub {
            my $res = $ua->request(POST "http://localhost:$port/secure_login");

            ok $res->header('set-cookie') =~ /myapp_session=(.+?);/;
            isnt $1, $cookie, 'sid was regenerated';
        };

        subtest 'Test GET / after login' => sub {
            my $res = $ua->request(GET "http://localhost:$port/");

            is $res->content, 'Fuga';
            is $res->header('set-cookie'), undef;
        };
    },
);

# Flash handling
test_tcp(
    server => $server,
    client => sub {
        my $port = shift;
        my $ua = Plack::LWPish->new(
            cookie_jar => HTTP::CookieJar->new,
        );

        subtest 'Test POST /flash' => sub {
            my $res = $ua->request(POST "http://localhost:$port/flash");

            is $res->content, 'OK';
        };

        subtest 'Test GET /flash' => sub {
            my $res1 = $ua->request(GET "http://localhost:$port/flash");
            my $res2 = $ua->request(GET "http://localhost:$port/flash");

            is $res1->content, 'HogeFuga';
            is $res2->content, '';
        };

        subtest 'Test GET /static_file.html does not erase flash' => sub {
            # Set 'HogeFuga' in flash
            $ua->request(POST "http://localhost:$port/flash");

            {   # Request a static file
                my $res = $ua->request(GET "http://localhost:$port/static_file.html");

                is $res->content, "Hello, world.\n";
            };

            my $res1 = $ua->request(GET "http://localhost:$port/flash");
            my $res2 = $ua->request(GET "http://localhost:$port/flash");

            is $res1->content, 'HogeFuga', 'flash content remains after static file dispatch';
            is $res2->content, '', 'flash content expires after non-static dispatch';
        };
    },
);

done_testing;

__DATA__

@@ static_file.html
Hello, world.
