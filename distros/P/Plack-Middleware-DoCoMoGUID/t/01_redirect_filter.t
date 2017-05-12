use strict;
use warnings;
use Test::More;
use HTTP::Request;
use Plack::Test;
use Plack::Builder;
use Plack::Request;

for my $middleware ( qw( DoCoMoGUID::RedirectFilter DoCoMoGUID ) ) {
    subtest $middleware => sub {
        subtest 'do filter case' => sub {
            test_psgi(
                app => sub {
                    my $env = shift;
                    my $app = builder {
                        enable 'Lint';
                        enable $middleware;
                        enable 'Lint';
                        sub {
                            my $env = shift;
                            my $req = Plack::Request->new($env);
                            return [302, [Location => $req->uri->as_string], []];
                        };
                    };
                    $app->($env);
                },
                client => sub {
                    my $cb = shift;
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?guid=ON&foo=bar', 'guid=ON should set');
                    }
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar&guid=FOO");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?foo=bar&guid=FOO', 'should not append guid=ON');
                    }
                },
            );

            done_testing();
        };

        subtest 'do filter case with extra params' => sub {
            test_psgi(
                app => sub {
                    my $env = shift;
                    my $app = builder {
                        enable 'Lint';
                        enable $middleware, params => { hoge => 'fuga', fugo => 'haga'};
                        enable 'Lint';
                        sub {
                            my $env = shift;
                            my $req = Plack::Request->new($env);
                            return [302, [Location => $req->uri->as_string], []];
                        };
                    };
                    $app->($env);
                },
                client => sub {
                    my $cb = shift;
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?guid=ON&hoge=fuga&fugo=haga&foo=bar', 'guid=ON should set');
                    }
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar&guid=FOO");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?hoge=fuga&fugo=haga&foo=bar&guid=FOO', 'should not append guid=ON');
                    }
                },
            );

            done_testing();
        };

        subtest 'should not work filter case' => sub {
            test_psgi(
                app => sub {
                    my $env = shift;
                    my $app = builder {
                        enable 'Lint';
                        enable $middleware;
                        enable 'Lint';
                        sub {
                            my $env = shift;
                            my $req = Plack::Request->new($env);
                            return [302, [Location => "http://example.com/?foo=bar" ], []];
                        };
                    };
                    $app->($env);
                },
                client => sub {
                    my $cb = shift;
                    my $req = HTTP::Request->new(GET => "http://localhost/hello?guid=ON");
                    my $res = $cb->($req);
                    is($res->header('location'), 'http://example.com/?foo=bar');
                },
            );

            done_testing();
        };

        done_testing;
    };
}
done_testing();

